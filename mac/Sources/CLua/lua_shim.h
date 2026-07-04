#ifndef LUA_SHIM_H
#define LUA_SHIM_H

#include "lua.h"
#include <stddef.h>

/* Output sink: receives bytes produced by print()/errors. */
typedef void (*clua_writer)(const char *s, size_t len, void *ctx);

/* Create a fresh Lua state with the standard libraries, a print() that routes
 * to the writer, a permissive Electra-API mock (so device calls don't crash),
 * and an instruction-count guard against infinite loops. If the mock preamble
 * fails to run, its error message is stored in the `__preamble_err` global for
 * the host to report. */
lua_State *clua_new(clua_writer w, void *ctx);

void clua_close(lua_State *L);

/* Compile + run a chunk, then call common entry points (init/onLoad/onReady)
 * if defined. Output and errors go to the writer. Returns 0 on success,
 * -1 on a compile/runtime error. */
int clua_run(lua_State *L, const char *src);

/* Invoke the paint callback registered for control `id` (via setPaintCallback),
 * rendering at size w×h with a normalized value `frac` (0..1). Records the draw
 * calls into the `__draw_json` global. Returns 0 on success, 1 if no paint
 * callback is registered for the id, and -1 if the callback (or the render
 * machinery) errored — the error message is stored in the `__render_err`
 * global. Call after clua_run has loaded the script. */
int clua_render(lua_State *L, int id, double w, double h, double frac);

/* Length in bytes of a global string variable (0 if absent or not a string).
 * Lets the host size a buffer exactly before calling clua_global_string, so
 * large values (e.g. `__draw_json`) are never truncated. */
size_t clua_global_strlen(lua_State *L, const char *name);

/* Read a global string variable into `out` (NUL-terminated, truncated to `cap`).
 * Returns 1 if the global was a string, 0 otherwise. Used by the simulator to
 * pull back observable state (e.g. the `__sim_bottom` status-bar text). */
int clua_global_string(lua_State *L, const char *name, char *out, size_t cap);

/* Syntax-check only (no execution). Returns 0 if it compiles, else -1 and
 * writes the error message. Uses a throwaway state. */
int clua_check(const char *src, clua_writer w, void *ctx);

#endif
