// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (c) 2023 Marko Petrović
#include "lua.h"
#include <QString>
#include <QStringList>

int parse(lua_State* L)
{
    if (!lua_isstring(L, 2)) {
        lua_pushstring(L, "");
        return 1;
    }
    QString text(lua_tostring(L, 2));
    lua_Integer minLen = lua_tointeger(L, 1);

    QString result;
    for (QString &word : text.split(" ")) {
        if (word.size() <= minLen) {
            result += word + " ";
            continue;
        }
        QChar first = word[0];
        word = word.toLower();
        word[0] = first;
        result += word + " ";
    }
    lua_pushstring(L, result.toUtf8().data());
    return 1;
}

extern "C" int luaopen_mylibrary(lua_State* L)
{
    lua_newtable(L);
    lua_pushcfunction(L, parse);
    lua_setfield(L, -2, "parse");

    return 1;
}
