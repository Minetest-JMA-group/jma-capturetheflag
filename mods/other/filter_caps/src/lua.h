#ifndef LUA_H
#define LUA_H
#include <lua-5.1/lua.hpp>
#include <QTextStream>
#define qPrint QTextStream(stdout)

extern "C" int luaopen_mylibrary(lua_State* L);

#endif // LUA_H
