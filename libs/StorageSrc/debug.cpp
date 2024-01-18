// SPDX-License-Identifier: LGPL-2.1-only
// Copyright (c) 2023 Marko Petrović
#include "minetest.h"

void printLuaStack(lua_State* L) {
    int top = lua_gettop(L);
    QTextStream qPrint(stdout);
    qPrint << "Lua Stack State (top to bottom):\n";

    for (int i = top; i >= 1; i--) {
        int type = lua_type(L, i);
        qPrint << i << " ";

        switch (type) {
        case LUA_TNIL:
            qPrint << "NIL\n";
            break;
        case LUA_TBOOLEAN:
            qPrint << (lua_toboolean(L, i) ? "true\n" : "false\n");
            break;
        case LUA_TNUMBER:
            qPrint << lua_tonumber(L, i) << "\n";
            break;
        case LUA_TSTRING:
            qPrint << lua_tostring(L, i) << "\n";
            break;
        case LUA_TTABLE:
            qPrint << "TABLE\n";
            break;
        case LUA_TFUNCTION:
            qPrint << "FUNCTION\n";
            break;
        case LUA_TUSERDATA:
            qPrint << "USERDATA\n";
            break;
        case LUA_TTHREAD:
            qPrint << "THREAD\n";
            break;
        case LUA_TLIGHTUSERDATA:
            qPrint << "LIGHT USERDATA\n";
            break;
        default:
            qPrint << "Unknown\n";
            break;
        }
    }
}
