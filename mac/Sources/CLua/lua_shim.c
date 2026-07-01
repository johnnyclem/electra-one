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
 * the standard libraries are real. A few high-value modules (info, controller)
 * are mocked concretely so the in-app simulator can observe their effects:
 * info.setText records the bottom-bar text into `__sim_bottom`. */
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
/* device-accurate 24-bit colors so graphics recording draws the right hue */
"WHITE=0xFFFFFF RED=0xF20530 ORANGE=0xF57000 YELLOW=0xFFD500 GREEN=0x00A000 BLUE=0x0060C0 PURPLE=0xA000C0\n"
"X=1 Y=2 WIDTH=3 HEIGHT=4\n"
"LEFT=0 CENTER=1 RIGHT=2\n"
"TOP_LEFT=0 TOP_RIGHT=1 BOTTOM_LEFT=2 BOTTOM_RIGHT=3\n"
/* ── simulator-observable modules ───────────────────────────────────────────── */
"__sim_bottom = nil\n"
"info = setmetatable({\n"
"  setText = function(s) __sim_bottom = tostring(s); print('info.setText: '..tostring(s)) end,\n"
"}, { __index = function() return function() end end })\n"
"controller = setmetatable({\n"
"  getModel = function() return 'mk2' end,\n"
"  getNumModel = function() return 2 end,\n"
"  getFirmwareVersion = function() return '4.0.0' end,\n"
"  getFirmwareNumVersion = function() return 400000000 end,\n"
"  uptime = function() return 0 end,\n"
"  isRequired = function() return true end,\n"
"  require = function() return true end,\n"
"}, { __index = function() return function() end end })\n"
/* ── graphics recorder ──────────────────────────────────────────────────────
 * A real `graphics` module that records every draw call into `__draw` so the
 * host can replay them on a canvas (this is what makes script-drawn Custom
 * controls actually render in-app). Each op is a fixed row:
 *   op, x, y, a, b, c, d, color, text   (unused numeric slots are 0). */
"__draw = {}\n"
"__cur_color = 0xFFFFFF\n"
"__paint_cbs = {}\n"
"__ctl_cache = {}\n"
"__render_val = 0\n"
"local function __push(op,x,y,a,b,c,d,text)\n"
"  __draw[#__draw+1] = {op=op, x=x or 0, y=y or 0, a=a or 0, b=b or 0, c=c or 0, d=d or 0, color=__cur_color, text=text}\n"
"end\n"
"graphics = {\n"
"  setColor      = function(c) __cur_color = c or 0xFFFFFF end,\n"
"  drawPixel     = function(x,y) __push('pixel',x,y) end,\n"
"  drawLine      = function(x1,y1,x2,y2) __push('line',x1,y1,x2,y2) end,\n"
"  drawRect      = function(x,y,w,h) __push('rect',x,y,w,h) end,\n"
"  fillRect      = function(x,y,w,h) __push('fillRect',x,y,w,h) end,\n"
"  drawRoundRect = function(x,y,w,h,r) __push('roundRect',x,y,w,h,r) end,\n"
"  fillRoundRect = function(x,y,w,h,r) __push('fillRoundRect',x,y,w,h,r) end,\n"
"  drawTriangle  = function(x1,y1,x2,y2,x3,y3) __push('triangle',x1,y1,x2,y2,x3,y3) end,\n"
"  fillTriangle  = function(x1,y1,x2,y2,x3,y3) __push('fillTriangle',x1,y1,x2,y2,x3,y3) end,\n"
"  drawCircle    = function(x,y,r) __push('circle',x,y,r) end,\n"
"  fillCircle    = function(x,y,r) __push('fillCircle',x,y,r) end,\n"
"  drawEllipse   = function(x,y,rx,ry) __push('ellipse',x,y,rx,ry) end,\n"
"  fillEllipse   = function(x,y,rx,ry) __push('fillEllipse',x,y,rx,ry) end,\n"
"  fillCurve     = function(x,y,r,seg) __push('curve',x,y,r,seg) end,\n"
"  print         = function(x,y,text,w,a) __push('text',x,y,w,a,0,0,tostring(text)) end,\n"
"}\n"
/* controls.get(id): a permissive control whose setPaintCallback is captured and
 * whose getBounds reflects the size the host asked us to render at. */
"local function __makeControl(id)\n"
"  local bounds = {0,0,0,0}\n"
"  local self = {}\n"
"  self.getBounds = function() return {bounds[1],bounds[2],bounds[3],bounds[4]} end\n"
"  self.setBounds = function(b) if type(b)=='table' then bounds={b[1] or 0,b[2] or 0,b[3] or 0,b[4] or 0} end end\n"
"  self.setPaintCallback = function(a,b) __paint_cbs[id] = b or a end\n"
"  self.repaint = function() end\n"
"  self.getValue = function() return __render_val end\n"
"  self.__setbounds = function(b) bounds = b end\n"
"  return setmetatable(self, { __index = function() return function() return self end end })\n"
"end\n"
"controls = setmetatable({\n"
"  get = function(id) if not __ctl_cache[id] then __ctl_cache[id]=__makeControl(id) end return __ctl_cache[id] end,\n"
"}, { __index = function() return function() end end })\n"
/* concrete `preset` so `function preset.onReady()` is retrievable — lets the
 * in-app renderer register paint callbacks the same way the device does. */
"preset = setmetatable({}, { __index = function() return function() end end })\n"
/* serialize + render one control's paint callback at a given size/value */
"function __serialize(ops)\n"
"  local t = {}\n"
"  for i=1,#ops do\n"
"    local o = ops[i]\n"
"    local text = o.text and o.text:gsub('[\\t\\n\\r]',' ') or ''\n"
"    t[#t+1] = string.format('%s\\t%g\\t%g\\t%g\\t%g\\t%g\\t%g\\t%d\\t%s', o.op, o.x, o.y, o.a, o.b, o.c, o.d, o.color, text)\n"
"  end\n"
"  return table.concat(t, '\\n')\n"
"end\n"
"function __render(id, w, h, frac)\n"
"  __draw = {}\n"
"  __cur_color = 0xFFFFFF\n"
"  __render_val = math.floor((frac or 0)*127 + 0.5)\n"
"  if rawget(preset, 'onLoad') then pcall(preset.onLoad) end\n"
"  if rawget(preset, 'onReady') then pcall(preset.onReady) end\n"
"  local ctl = controls.get(id)\n"
"  ctl.__setbounds({0,0,w,h})\n"
"  local cb = __paint_cbs[id]\n"
"  if cb then pcall(cb, ctl) end\n"
"  __draw_json = __serialize(__draw)\n"
"end\n";

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

int clua_render(lua_State *L, int id, double w, double h, double frac) {
    lua_getglobal(L, "__render");
    if (!lua_isfunction(L, -1)) { lua_pop(L, 1); return -1; }
    lua_pushinteger(L, id);
    lua_pushnumber(L, w);
    lua_pushnumber(L, h);
    lua_pushnumber(L, frac);
    if (lua_pcall(L, 4, 0, 0) != LUA_OK) { lua_pop(L, 1); return -1; }
    return 0;
}

int clua_global_string(lua_State *L, const char *name, char *out, size_t cap) {
    if (!L || !name || !out || cap == 0) return 0;
    lua_getglobal(L, name);
    int found = 0;
    if (lua_isstring(L, -1)) {
        size_t len = 0;
        const char *s = lua_tolstring(L, -1, &len);
        if (s) {
            if (len >= cap) len = cap - 1;
            memcpy(out, s, len);
            out[len] = '\0';
            found = 1;
        }
    }
    lua_pop(L, 1);
    return found;
}

int clua_check(const char *src, clua_writer w, void *ctx) {
    lua_State *L = luaL_newstate();
    if (!L) return -1;
    int rc = 0;
    if (luaL_loadstring(L, src) != LUA_OK) { write_err(w, ctx, L); rc = -1; }
    lua_close(L);
    return rc;
}
