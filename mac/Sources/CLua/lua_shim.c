#include "lua_shim.h"
#include "lauxlib.h"
#include "lualib.h"
#include <string.h>

/* ── print() → writer ─────────────────────────────────────────────────────── */

static int l_print(lua_State *L) {
    clua_writer w = (clua_writer)lua_touserdata(L, lua_upvalueindex(1));
    void *ctx = lua_touserdata(L, lua_upvalueindex(2));
    int n = lua_gettop(L);
    for (int i = 1; i <= n; i++) {
        size_t len = 0;
        const char *s = luaL_tolstring(L, i, &len); /* handles __tostring */
        if (i > 1 && w) w("\t", 1, ctx);
        if (w && s) w(s, len, ctx);
        lua_pop(L, 1); /* pop luaL_tolstring result */
    }
    if (w) w("\n", 1, ctx);
    return 0;
}

/* ── infinite-loop guard ──────────────────────────────────────────────────── */

static void l_hook(lua_State *L, lua_Debug *ar) {
    (void)ar;
    luaL_error(L, "execution stopped: instruction limit reached (possible infinite loop)");
}

/* ── permissive Electra-API mock ──────────────────────────────────────────────
 * Any undefined global resolves to a benign callable/indexable proxy so scripts
 * that drive the device API run without 'attempt to index nil' errors. print and
 * the standard libraries are real. */
static const char *PREAMBLE =
"local function mock(name)\n"
"  local t = {}\n"
"  local mt = {}\n"
"  mt.__index = function(_, k) return mock(name) end\n"
"  mt.__call  = function(_, ...) return mock(name) end\n"
"  mt.__tostring = function() return '<'..name..'>' end\n"
"  mt.__add = function() return 0 end\n"
"  mt.__sub = function() return 0 end\n"
"  mt.__mul = function() return 0 end\n"
"  mt.__div = function() return 0 end\n"
"  mt.__mod = function() return 0 end\n"
"  mt.__unm = function() return 0 end\n"
"  mt.__len = function() return 0 end\n"
"  mt.__eq  = function() return false end\n"
"  mt.__lt  = function() return false end\n"
"  mt.__le  = function() return false end\n"
"  mt.__concat = function(a,b) return tostring(a)..tostring(b) end\n"
"  return setmetatable(t, mt)\n"
"end\n"
"setmetatable(_G, { __index = function(_, k) return mock(k) end })\n"
/* a few commonly-read constants scripts compare against */
"PORT_1=1 PORT_2=2 PORT_CTRL=3 USB_DEV=0 USB_HOST=1 MIDI_IO=2\n"
"RED='RED' ORANGE='ORANGE' YELLOW='YELLOW' GREEN='GREEN' BLUE='BLUE' PURPLE='PURPLE' WHITE='WHITE'\n";

static void install_print(lua_State *L, clua_writer w, void *ctx) {
    lua_pushlightuserdata(L, (void *)w);
    lua_pushlightuserdata(L, ctx);
    lua_pushcclosure(L, l_print, 2);
    lua_setglobal(L, "print");
}

lua_State *clua_new(clua_writer w, void *ctx) {
    lua_State *L = luaL_newstate();
    if (!L) return NULL;
    luaL_openlibs(L);
    /* mock first, then real print so print wins */
    (void)luaL_dostring(L, PREAMBLE);
    install_print(L, w, ctx);
    /* stash the writer/ctx for error reporting */
    lua_pushlightuserdata(L, (void *)w);
    lua_setfield(L, LUA_REGISTRYINDEX, "clua_w");
    lua_pushlightuserdata(L, ctx);
    lua_setfield(L, LUA_REGISTRYINDEX, "clua_ctx");
    lua_sethook(L, l_hook, LUA_MASKCOUNT, 20000000);
    return L;
}

void clua_close(lua_State *L) {
    if (L) lua_close(L);
}

static void write_err(clua_writer w, void *ctx, lua_State *L) {
    size_t len = 0;
    const char *msg = lua_tolstring(L, -1, &len);
    if (msg && w) { w(msg, len, ctx); w("\n", 1, ctx); }
    lua_pop(L, 1);
}

int clua_run(lua_State *L, const char *src) {
    lua_getfield(L, LUA_REGISTRYINDEX, "clua_w");
    clua_writer w = (clua_writer)lua_touserdata(L, -1);
    lua_pop(L, 1);
    lua_getfield(L, LUA_REGISTRYINDEX, "clua_ctx");
    void *ctx = lua_touserdata(L, -1);
    lua_pop(L, 1);

    if (luaL_loadstring(L, src) != LUA_OK) { write_err(w, ctx, L); return -1; }
    if (lua_pcall(L, 0, 0, 0) != LUA_OK) { write_err(w, ctx, L); return -1; }

    /* Call common entry points if the script defined them. */
    const char *entries[] = { "init", "onLoad", "onReady", "onEnter", NULL };
    for (int i = 0; entries[i]; i++) {
        lua_getglobal(L, entries[i]);
        if (lua_isfunction(L, -1)) {
            if (w) { char buf[64]; int n = snprintf(buf, sizeof buf, "-- calling %s() --\n", entries[i]); w(buf, (size_t)n, ctx); }
            if (lua_pcall(L, 0, 0, 0) != LUA_OK) { write_err(w, ctx, L); return -1; }
        } else {
            lua_pop(L, 1);
        }
    }
    return 0;
}

int clua_check(const char *src, clua_writer w, void *ctx) {
    lua_State *L = luaL_newstate();
    if (!L) return -1;
    int rc = 0;
    if (luaL_loadstring(L, src) != LUA_OK) { write_err(w, ctx, L); rc = -1; }
    lua_close(L);
    return rc;
}
