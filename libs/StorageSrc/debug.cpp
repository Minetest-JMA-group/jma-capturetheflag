// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (c) 2023 Marko Petrović
#include <minetest.h>

void printLuaType(lua_State *L, int index, QTextStream &where)
{
    int type = lua_type(L, index);
    where << lua_typename(L, type);
    switch (type) {
    case LUA_TBOOLEAN:
        where << ": " << (lua_toboolean(L, index) ? "true" : "false");
        break;
    case LUA_TNUMBER:
        where << ": " << lua_tonumber(L, index);
        break;
    case LUA_TSTRING:
        where << ": " << lua_tostring(L, index);
        break;
    }
    where << "\n";
}

void printLuaStack(lua_State* L) {
    int top = lua_gettop(L);
    QTextStream qPrint(stdout);
    qPrint << "Lua Stack State (top to bottom):\n";

    for (int i = top; i >= 1; i--) {
        qPrint << i << " ";
        printLuaType(L, i, qPrint);
    }
}

void printLuaTable(lua_State *L, int index) {
    QTextStream qPrint(stdout);
    if (index < 0)
        index = lua_gettop(L) + index + 1;
    // Make sure the value at the given index is a table
    if (!lua_istable(L, index)) {
        qPrint << "Not a table\n";
        return;
    }

    // Push the first key onto the stack
    lua_pushnil(L);

    // Iterate over the table
    while (lua_next(L, index) != 0) {
        // Key is at index -2 and value is at index -1 on the stack
        // Print key-value pair
        qPrint << "Key: ";
        printLuaType(L, -2, qPrint);
        qPrint << "Value: ";
        printLuaType(L, -1, qPrint);
        qPrint << "\n";

        // Pop the value, leaving the key on the top for the next iteration
        lua_pop(L, 1);
    }
}
