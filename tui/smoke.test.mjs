// Smoke test: render the real App against the connected device (read-only),
// drive a few keypresses, and print captured frames. Not a unit test — a
// manual end-to-end render check that needs the hardware attached.
import React from 'react';
import { render } from 'ink-testing-library';
import htm from 'htm';
import { App } from './app.mjs';
import { createRequire } from 'node:module';

const require = createRequire(import.meta.url);
const transport = require('../lib/transport');
const html = htm.bind(React.createElement);

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

(async () => {
  const inst = render(html`<${App} />`);

  await sleep(800);
  console.log('\n──── after connect ────');
  console.log(inst.lastFrame());

  // wait for scan to populate
  await sleep(6000);
  console.log('\n──── after scan ────');
  console.log(inst.lastFrame());

  // move down twice and view slot
  inst.stdin.write('j');
  inst.stdin.write('j');
  inst.stdin.write('\r'); // Enter -> view
  await sleep(2500);
  console.log('\n──── after viewing slot 2 ────');
  console.log(inst.lastFrame());

  // open upload prompt then cancel
  inst.stdin.write('u');
  await sleep(200);
  inst.stdin.write('/tmp/x.json');
  await sleep(200);
  console.log('\n──── upload prompt ────');
  console.log(inst.lastFrame());
  inst.stdin.write(''); // ESC cancel
  await sleep(300);

  inst.unmount();
  transport.disconnect();
  console.log('\n✓ smoke test completed without render crash');
  process.exit(0);
})().catch((e) => { console.error('SMOKE FAIL:', e); process.exit(1); });
