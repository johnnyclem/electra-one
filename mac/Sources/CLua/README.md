# CLua

Vendored **Lua 5.4.7** (the reference C implementation), compiled as a SwiftPM C
target so the app can build/run Lua scripts in-process for the editor preview.

- Upstream: https://github.com/lua/lua (tag `v5.4.7`)
- License: **MIT** — Copyright © 1994–2024 Lua.org, PUC-Rio (see the copyright
  notice in `lua.h`).

The standalone `lua.c` and `luac.c` (which define `main`) are intentionally
omitted. `lua_shim.{h,c}` is our thin C layer that exposes Swift-friendly
entry points (print capture, the permissive Electra-API mock, and an
instruction-count guard against infinite loops); see `LuaKit/LuaEngine.swift`.
