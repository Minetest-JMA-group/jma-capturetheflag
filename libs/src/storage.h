#ifndef STORAGE_H
#define STORAGE_H
#include <lua-5.1/lua.hpp>
#include <QString>
#define INT_ERROR std::numeric_limits<lua_Integer>::min()

// Assume that Lua table storage is on the top of the stack
class storage {
private:
    lua_State *L;
public:
    storage(lua_State *L);
    lua_Integer get_int(const QString &key);
    QString get_string(const QString &key);
    bool set_int(const QString &key, lua_Integer a);
    bool set_string(const QString &key, const QString &str);
};

void printLuaStack(lua_State* L);
inline bool lua_isinteger(lua_State *L, int index)
{
    return lua_type(L, index) == LUA_TNUMBER;
}

#endif // STORAGE_H
