// SPDX-License-Identifier: LGPL-2.1-only
// Copyright (c) 2023 Marko Petrović
#include "lua.h"
#include <QString>

int countCaps(lua_State* L)
{
    if (!lua_isstring(L, 1)) {
        lua_pushinteger(L, 0);
        return 1;
    }
    QString str(lua_tostring(L, 1));
    int upperCase = 0;
    for (const QChar &ch : str)
        if (ch.isUpper())
                upperCase++;

    lua_pushinteger(L, upperCase);
    return 1;
}

int lower(lua_State* L)
{
    if (!lua_isstring(L, 1)) {
        lua_pushstring(L, "");
        return 1;
    }
    QString str(lua_tostring(L, 1));
    lua_pushstring(L, str.toLower().toUtf8().data());
    return 1;
}

int upper(lua_State* L)
{
    if (!lua_isstring(L, 1)) {
        lua_pushstring(L, "");
        return 1;
    }
    QString str(lua_tostring(L, 1));
    lua_pushstring(L, str.toUpper().toUtf8().data());
    return 1;
}

extern "C" int luaopen_mylibrary(lua_State* L)
{
    lua_newtable(L);
    lua_pushcfunction(L, countCaps);
    lua_setfield(L, -2, "countCaps");
    lua_pushcfunction(L, lower);
    lua_setfield(L, -2, "lower");
    lua_pushcfunction(L, upper);
    lua_setfield(L, -2, "upper");
    return 1;
}
