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

extern "C" int luaopen_mylibrary(lua_State* L)
{
    lua_newtable(L);
    lua_pushcfunction(L, countCaps);
    lua_setfield(L, -2, "countCaps");
    return 1;
}
