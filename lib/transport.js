'use strict';

/**
 * transport.js
 *
 * MIDI I/O: port discovery, send, receive.
 * No Electra One protocol knowledge here — just byte transport.
 *
 * Connection model (v2 — persistent):
 *
 *   The previous version opened and closed the CoreMIDI ports on *every*
 *   query/command via a `withPorts` wrapper. On macOS this crashes libuv
 *   after a handful of operations:
 *
 *       Assertion failed: (handle->flags & UV_HANDLE_CLOSING),
 *       function uv__finish_close, file core.c
 *
 *   Repeatedly opening/closing the same node-midi handle (and adding/removing
 *   listeners) confuses libuv's close bookkeeping. The fix is to open the
 *   ports ONCE (connect) and keep them open for the life of the process,
 *   reusing a single persistent 'message' listener. A TUI needs exactly this
 *   persistent session anyway.
 *
 *   Requests are serialized through an internal queue so only one SysEx
 *   exchange is in flight at a time, matching how the device responds.
 *
 * Still handled from v1:
 *
 *   - CoreMIDI -304 (kMIDIClientCreateErr): one shared Input/Output pair for
 *     the whole process, used for both enumeration and I/O.
 *   - SysEx fragmentation: CoreMIDI splits large payloads across multiple
 *     'message' events; we reassemble until EOX (0xF7).
 */

const midi    = require('midi');
const { classify, SOX, EOX } = require('./protocol');

/**
 * Thrown when the device does not answer within the exchange timeout.
 * Carries `.timeout = true` so callers can distinguish "no answer" from
 * other failures without matching on message strings.
 */
class TimeoutError extends Error {
  constructor(message = 'Timeout — device did not respond') {
    super(message);
    this.name = 'TimeoutError';
    this.timeout = true;
  }
}

// ── Shared MIDI client (singleton) ────────────────────────────────────────────

let _input  = null;
let _output = null;

/**
 * Return the shared Input/Output pair, creating it on first call.
 * Reusing these objects avoids registering multiple CoreMIDI clients.
 */
function getShared() {
  if (!_input) {
    _input  = new midi.Input();
    _output = new midi.Output();
    _input.ignoreTypes(false, false, false); // never filter SysEx
  }
  return { input: _input, output: _output };
}

// ── Port enumeration ──────────────────────────────────────────────────────────

/**
 * List all available MIDI port names.
 * Uses the shared MIDI objects — no extra CoreMIDI clients created.
 * @returns {{ inputs: string[], outputs: string[] }}
 */
function listAllPorts() {
  const { input, output } = getShared();
  const inputs  = Array.from({ length: input.getPortCount()  }, (_, i) => input.getPortName(i));
  const outputs = Array.from({ length: output.getPortCount() }, (_, i) => output.getPortName(i));
  return { inputs, outputs };
}

/**
 * Score a port name for likelihood of being the Electra One CTRL port.
 * Higher is better; -1 = not E1.
 * @param {string} name
 * @returns {number}
 */
function scorePort(name) {
  if (!name.includes('Electra')) return -1;
  if (name.includes('CTRL'))     return 3;  // preferred management port
  if (name.includes('PORT 3'))   return 2;  // Linux alias
  if (name.includes('MIDIIN3'))  return 2;  // Windows alias
  return 1;
}

/**
 * Find the best Electra One input and output port indices.
 * @returns {{ inputPort: number, outputPort: number, inputName: string|null, outputName: string|null }}
 */
function findE1Ports() {
  const { inputs, outputs } = listAllPorts();
  const best = (names) => {
    let bestIdx = -1, bestScore = -1;
    names.forEach((name, i) => {
      const score = scorePort(name);
      if (score > bestScore) { bestIdx = i; bestScore = score; }
    });
    return bestScore > 0 ? bestIdx : -1;
  };

  const inputPort  = best(inputs);
  const outputPort = best(outputs);
  return {
    inputPort,
    outputPort,
    inputName:  inputs[inputPort]   ?? null,
    outputName: outputs[outputPort] ?? null,
  };
}

// ── SysEx accumulator ─────────────────────────────────────────────────────────

/**
 * Create a stateful accumulator that reassembles fragmented SysEx messages.
 *
 * CoreMIDI can split large SysEx payloads across multiple `message` events.
 * Each call to feed(bytes) appends to an internal buffer. When EOX (0xF7) is
 * seen, feed returns the complete assembled message and resets. Returns null
 * while still accumulating.
 *
 * @returns {(bytes: number[]) => number[]|null}
 */
function makeSysExAccumulator() {
  let buf = [];
  return function feed(bytes) {
    if (bytes[0] === SOX) {
      buf = [...bytes];           // new message — reset
    } else if (buf.length > 0) {
      buf = buf.concat(bytes);    // continuation fragment
    } else {
      return null;                // non-SysEx with no active buffer — ignore
    }

    if (buf[buf.length - 1] === EOX) {
      const complete = buf;
      buf = [];
      return complete;
    }

    return null; // still accumulating
  };
}

// ── Persistent connection ─────────────────────────────────────────────────────

let _connected   = false;
let _onComplete   = null;          // current waiter for a complete SysEx message
let _queue        = Promise.resolve(); // serializes exchanges
let _portNames    = { inputName: null, outputName: null };

/**
 * Open the Electra One ports and attach the persistent message listener.
 * Idempotent — calling again while connected is a no-op.
 *
 * @returns {{ inputName: string, outputName: string }}
 */
function connect() {
  if (_connected) return _portNames;

  const { inputPort, outputPort, inputName, outputName } = findE1Ports();
  if (inputPort === -1 || outputPort === -1) {
    throw new Error(
      'Electra One not found — is it plugged in?\n' +
      'Run `e1 ports` to list available MIDI ports.'
    );
  }

  const { input, output } = getShared();
  input.openPort(inputPort);
  output.openPort(outputPort);

  const feed = makeSysExAccumulator();
  input.on('message', (_dt, msg) => {
    const complete = feed(Array.from(msg));
    if (!complete) return;            // still accumulating a fragmented message
    if (_onComplete) _onComplete(classify(complete));
  });

  _connected = true;
  _portNames = { inputName, outputName };
  return _portNames;
}

/**
 * Close the ports and detach listeners. Safe to call when not connected.
 */
function disconnect() {
  if (!_connected) return;
  try { _input.removeAllListeners('message'); } catch {}
  try { _input.closePort();  } catch {}
  try { _output.closePort(); } catch {}
  _connected = false;
  _onComplete = null;
  _queue = Promise.resolve(); // drop any backed-up exchanges from this session
}

/** @returns {boolean} */
function isConnected() {
  return _connected;
}

// ── Send and receive ──────────────────────────────────────────────────────────

/**
 * Send a SysEx message, then resolve the first complete response for which
 * `match(parsed)` returns a non-undefined value. Returning an Error rejects;
 * any other value resolves. Returning undefined keeps waiting.
 *
 * Only one exchange runs at a time (callers go through the serializing queue).
 *
 * @param {number[]} msgBytes
 * @param {(parsed: object) => any} match
 * @param {number} timeoutMs
 * @param {string} timeoutMessage
 * @returns {Promise<any>}
 */
function _exchange(msgBytes, match, timeoutMs, timeoutMessage) {
  return new Promise((resolve, reject) => {
    let settled = false;
    let timer;

    const settle = (err, result) => {
      if (settled) return;
      settled = true;
      clearTimeout(timer);
      _onComplete = null;
      if (err) reject(err); else resolve(result);
    };

    _onComplete = (parsed) => {
      let r;
      try {
        r = match(parsed);
      } catch (e) {
        settle(e); // a throwing matcher must not escape into the MIDI listener
        return;
      }
      if (r === undefined) return;            // not what we're waiting for
      if (r instanceof Error) settle(r);
      else settle(null, r);
    };

    timer = setTimeout(() => settle(new TimeoutError(timeoutMessage)), timeoutMs);

    try {
      _output.sendMessage(msgBytes);
    } catch (e) {
      settle(e);
    }
  });
}

/**
 * Enqueue an exchange so exchanges run strictly one at a time.
 * @template T
 * @param {() => Promise<T>} fn
 * @returns {Promise<T>}
 */
function _enqueue(fn) {
  const run = _queue.then(fn, fn);
  _queue = run.then(() => {}, () => {}); // never let a rejection break the chain
  return run;
}

/**
 * Send a SysEx message and wait for a complete data response.
 * Auto-connects on first use. Handles fragmented responses transparently.
 *
 * @param {number[]} msgBytes
 * @param {object}  [opts]
 * @param {number}  [opts.timeoutMs=6000]
 * @param {number}  [opts.expectResource] - if set, data responses for a
 *   different resource are ignored (protects against late replies from a
 *   previous, timed-out exchange being delivered to this one)
 * @returns {Promise<{ resource: number, payload: number[] }>}
 */
function query(msgBytes, { timeoutMs = 6000, expectResource } = {}) {
  return _enqueue(() => {
    if (!_connected) connect();
    return _exchange(
      msgBytes,
      (parsed) => {
        if (parsed.type !== 'data') return undefined;
        if (expectResource != null && parsed.resource !== expectResource) return undefined;
        return { resource: parsed.resource, payload: parsed.payload };
      },
      timeoutMs,
      'Timeout — device did not respond'
    );
  });
}

/**
 * Send a SysEx command and wait for ACK or NACK.
 * Resolves on ACK, rejects on NACK or timeout. Auto-connects on first use.
 *
 * @param {number[]} msgBytes
 * @param {object}  [opts]
 * @param {number}  [opts.timeoutMs=6000]
 * @returns {Promise<void>}
 */
function command(msgBytes, { timeoutMs = 6000 } = {}) {
  return _enqueue(() => {
    if (!_connected) connect();
    return _exchange(
      msgBytes,
      (parsed) => {
        if (parsed.type === 'ack')  return null; // resolve void
        if (parsed.type === 'nack') return new Error('NACK — device rejected the command');
        return undefined;
      },
      timeoutMs,
      'Timeout — no ACK from device'
    );
  });
}

module.exports = {
  TimeoutError,
  listAllPorts, findE1Ports,
  connect, disconnect, isConnected,
  query, command,
};
