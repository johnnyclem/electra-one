#ifndef LUA_SHIM_H
#define LUA_SHIM_H

#include "lua.h"
#include <stddef.h>

/* Output sink: receives bytes produced by print()/errors. */
typedef void (*clua_writer)(const char *s, size_t len, void *ctx);

/* Create a fresh Lua state with the standard libraries, a print() that routes
 * to the writer, a permissive Electra-API mock (so device calls don't crash),
 * and an instruction-count guard against infinite loops. */
lua_State *clua_new(clua_writer w, void *ctx);

void clua_close(lua_State *L);

/* Compile + run a chunk, then call common entry points (init/onLoad/onReady)
 * if defined. Output and errors go to the writer. Returns 0 on success,
 * -1 on a compile/runtime error. */
int clua_run(lua_State *L, const char *src);

/* Syntax-check only (no execution). Returns 0 if it compiles, else -1 and
 * writes the error message. Uses a throwaway state. */
int clua_check(const char *src, clua_writer w, void *ctx);

#endif
