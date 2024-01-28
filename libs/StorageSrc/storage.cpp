// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (c) 2023 Marko Petrović
#include <storage.h>
#define qLog QTextStream(stderr)

lua_Integer storage::get_int(const QString &key)
{
    SAVE_STACK
    lua_Integer res;

    if (!lua_isuserdata(L, -1))
        goto err;
    lua_getfield(L, -1, "get_int"); // Assuming the StorageRef object is at the top of the stack
    if (!lua_isfunction(L, -1))
        goto err;

    lua_pushvalue(L, old_top);
    lua_pushstring(L, key.toUtf8().data());
    if (lua_pcall(L, 2, 1, 0)) {
        qLog << "Error calling storage function\n" << lua_tostring(L, -1) << "\n";
        goto err;
    }
    if (!lua_isinteger(L, -1))
        goto err;

    res = lua_tointeger(L, -1);
    RESTORE_STACK
    return res;
err:
    RESTORE_STACK
    return INT_ERROR;
}


QByteArray storage::get_string(const QString &key)
{
    SAVE_STACK
    QByteArray res;

    if (!lua_isuserdata(L, -1))
        goto err;

    lua_getfield(L, -1, "get_string"); // Assuming the StorageRef object is at the top of the stack
    if (!lua_isfunction(L, -1))
        goto err;

    lua_pushvalue(L, old_top);
    lua_pushstring(L, key.toUtf8().data());
    if (lua_pcall(L, 2, 1, 0)) {
        qLog << "Error calling storage function\n" << lua_tostring(L, -1) << "\n";
        goto err;
    }

    if (!lua_isstring(L, -1))
        goto err;

    res = lua_tostring(L, -1);
    RESTORE_STACK
    return res;
err:
    RESTORE_STACK
    return "";
}

bool storage::set_int(const QString &key, const lua_Integer a)
{
    SAVE_STACK

    if (!lua_isuserdata(L, -1))
        goto err;

    lua_getfield(L, -1, "set_int"); // Assuming the StorageRef object is at the top of the stack

    if (!lua_isfunction(L, -1))
        goto err;

    lua_pushvalue(L, old_top);
    lua_pushstring(L, key.toUtf8().data());
    lua_pushinteger(L, a);

    if (lua_pcall(L, 3, 0, 0)) {
        qLog << "Error calling storage function\n" << lua_tostring(L, -1) << "\n";
        goto err;
    }

    RESTORE_STACK
    return true;
err:
    RESTORE_STACK
    return false;
}

bool storage::set_string(const QString &key, const QByteArray &str)
{
    SAVE_STACK

    if (!lua_isuserdata(L, -1))
        goto err;

    lua_getfield(L, -1, "set_string"); // Assuming 'storage' is at the top of the stack

    if (!lua_isfunction(L, -1))
        goto err;

    lua_pushvalue(L, old_top);
    lua_pushstring(L, key.toUtf8().data());
    lua_pushstring(L, str.data());

    if (lua_pcall(L, 3, 0, 0)) {
        qLog << "Error calling storage function\n" << lua_tostring(L, -1) << "\n";
        goto err;
    }

    RESTORE_STACK
    return true;
err:
    RESTORE_STACK
    return false;
}
