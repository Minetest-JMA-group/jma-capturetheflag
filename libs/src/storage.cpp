#include "storage.h"

storage::storage(lua_State *L)
{
    this->L = L;
}

lua_Integer storage::get_int(const QString &key)
{
    int cur_top, old_top = lua_gettop(L);
    lua_Integer res;
    if (!lua_isuserdata(L, -1))
        goto err;
    lua_getfield(L, -1, "get_int"); // Assuming the StorageRef object is at the top of the stack
    if (!lua_isfunction(L, -1))
        goto err;

    lua_pushvalue(L, old_top);
    lua_pushstring(L, key.toUtf8().data());
    if (!lua_pcall(L, 2, 1, 0))
        goto err;
    if (!lua_isinteger(L, -1))
        goto err;

    res = lua_tointeger(L, -1);
    cur_top = lua_gettop(L);
    lua_pop(L, cur_top-old_top);
    return res;
err:
    cur_top = lua_gettop(L);
    lua_pop(L, cur_top-old_top);
    return INT_ERROR;
}


QString storage::get_string(const QString &key)
{
    int cur_top, old_top = lua_gettop(L);
    QString res;

    if (!lua_isuserdata(L, -1))
        goto err;

    lua_getfield(L, -1, "get_string"); // Assuming the StorageRef object is at the top of the stack
    if (!lua_isfunction(L, -1))
        goto err;

    lua_pushvalue(L, old_top);
    lua_pushstring(L, key.toUtf8().data());
    if (!lua_pcall(L, 2, 1, 0))
        goto err;

    if (!lua_isstring(L, -1))
        goto err;

    res = lua_tostring(L, -1);
    cur_top = lua_gettop(L);
    lua_pop(L, cur_top-old_top);
    return res;
err:
    cur_top = lua_gettop(L);
    lua_pop(L, cur_top-old_top);
    return "";
}

bool storage::set_int(const QString &key, lua_Integer a)
{
    int cur_top, old_top = lua_gettop(L);

    if (!lua_isuserdata(L, -1))
        goto err;

    lua_getfield(L, -1, "set_int"); // Assuming the StorageRef object is at the top of the stack

    if (!lua_isfunction(L, -1))
        goto err;

    lua_pushvalue(L, old_top);
    lua_pushstring(L, key.toUtf8().data());
    lua_pushinteger(L, a);

    if (!lua_pcall(L, 3, 0, 0))
        goto err;

    cur_top = lua_gettop(L);
    lua_pop(L, cur_top-old_top);
    return true;
err:
    cur_top = lua_gettop(L);
    lua_pop(L, cur_top-old_top);
    return false;
}

bool storage::set_string(const QString &key, const QString &str)
{
    int cur_top, old_top = lua_gettop(L);

    if (!lua_isuserdata(L, -1))
        goto err;

    lua_getfield(L, -1, "set_string"); // Assuming 'storage' is at the top of the stack

    if (!lua_isfunction(L, -1))
        goto err;

    lua_pushvalue(L, old_top);
    lua_pushstring(L, key.toUtf8().data());
    lua_pushstring(L, str.toUtf8().data());

    if (!lua_pcall(L, 3, 0, 0))
        goto err;

    cur_top = lua_gettop(L);
    lua_pop(L, cur_top - old_top);
    return true;
err:
    cur_top = lua_gettop(L);
    lua_pop(L, cur_top - old_top);
    return false;
}
