// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (c) 2023 Marko Petrović
#include <minetest.h>
#include <storage.h>
#include <QString>
#include <QStringList>

minetest m;
int capsSpace = 2;

int parse(lua_State* L)
{
    if (!lua_isstring(L, 2)) {
        lua_pushstring(L, "");
        return 1;
    }
    QString text(lua_tostring(L, 2));

    bool firstUpper = true; // Keep first uppercase char in the string preserved, for things like :D
    int currCapsSpace = 100000000;
    for (int i = 0; i < text.size(); i++) {
        if (text[i].isUpper()) {
            if (!firstUpper || currCapsSpace < capsSpace) {
                text[i] = text[i].toLower();
            }
            else
                firstUpper = false;
            currCapsSpace = -1;
        }
        if (!text[i].isLetter()) {
            firstUpper = true;
            currCapsSpace++;
        }
    }

    lua_pushstring(L, text.toUtf8().data());
    return 1;
}

struct cmd_ret set_capsSpace(QString &name, QString &param)
{
    bool success;
    int capsSpaceTry = param.toInt(&success);
    if (!success)
        return {false, QStringLiteral("You have to enter a valid number")};
    capsSpace = capsSpaceTry;

    m.get_mod_storage();
    storage s(m.L);
    s.set_int("capsSpace", capsSpace);
    m.pop_modstorage();
    return {true, QStringLiteral("capsSpace set to: ") + QString::number(capsSpace)};
}

extern "C" int luaopen_mylibrary(lua_State* L)
{
    m.set_state(L);
    m.get_mod_storage();
    m.pop_modstorage();


    lua_newtable(L);
    lua_pushcfunction(L, parse);
    lua_setfield(L, -2, "parse");
    lua_setglobal(L, "filter_parse");

    return 0;
}
