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
        QTextStream(stderr) << "printLuaTable: Argument not a table!\n";
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

void copyLuaTable(lua_State *L, int srcIndex, int destIndex)
{
    if (destIndex < 0)
        destIndex = lua_gettop(L) + destIndex + 1;
    if (srcIndex < 0)
        srcIndex = lua_gettop(L) + srcIndex + 1;

    if (!lua_istable(L, srcIndex) || !lua_istable(L, destIndex)) {
        QTextStream(stderr) << "copyLuaTable: Argument not a table!\n";
        return;
    }

    // Push the first key onto the stack
    lua_pushnil(L);

    while (lua_next(L, srcIndex) != 0) {
        // Key is at index -2 and value is at index -1 on the stack
        // Push the key copy onto the stack
        lua_pushvalue(L, -2);
        // Push the value copy onto the stack
        lua_pushvalue(L, -2);

        // Set the value at the corresponding key in the destination table
        lua_rawset(L, destIndex);

        // Pop the original value, leaving the key on the top for the next iteration
        lua_pop(L, 1);
    }
}
