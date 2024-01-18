// SPDX-License-Identifier: LGPL-2.1-only
// Copyright (c) 2023 Marko Petrović
#include "minetest.h"

lua_state_class::lua_state_class(lua_State *L) : L(L) {}
lua_state_class::lua_state_class() {}
minetest::minetest() {}

void lua_state_class::set_state(lua_State *L)
{
    if (L != nullptr)
        this->L = L;
}

/* StorageRef user object construction in engine (className = "StorageRef"):
    *(void **)(lua_newuserdata(L, sizeof(void *))) = o; // o - StorageRef pointer
    luaL_getmetatable(L, className);
    lua_setmetatable(L, -2);
*/

void minetest::get_mod_storage()
{
    if (StorageRef == nullptr) {
        lua_getglobal(L, "minetest");
        lua_getfield(L, -1, "get_mod_storage");
        lua_remove(L, -2);
        lua_call(L, 0, 1);
        void *retrievedPointer = lua_touserdata(L, -1);
        StorageRef = *(void **)retrievedPointer;
    }
    else {
        *(void **)(lua_newuserdata(L, sizeof(void *))) = StorageRef;
        luaL_getmetatable(L, "StorageRef");
        // Set nil for the __gc field in the metatable
        lua_pushnil(L);
        lua_setfield(L, -2, "__gc");
        lua_setmetatable(L, -2);
    }
}

void minetest::log_message(const QString &level, const QString &msg)
{
    SAVE_STACK

    lua_getglobal(L, "minetest");
    lua_getfield(L, -1, "log");

    lua_pushstring(L, level.toUtf8().data());
    lua_pushstring(L, msg.toUtf8().data());
    lua_call(L, 2, 0);

    RESTORE_STACK
}

void minetest::chat_send_all(const QString &msg)
{
    SAVE_STACK

    lua_getglobal(L, "minetest");
    lua_getfield(L, -1, "chat_send_all");

    lua_pushstring(L, msg.toUtf8().data());
    lua_call(L, 1, 0);

    RESTORE_STACK
}

void minetest::chat_send_player(const QString &playername, const QString &msg)
{
    SAVE_STACK

    lua_getglobal(L, "minetest");
    lua_getfield(L, -1, "chat_send_player");

    lua_pushstring(L, playername.toUtf8().data());
    lua_pushstring(L, msg.toUtf8().data());
    lua_call(L, 2, 0);

    RESTORE_STACK
}

int minetest::lua_callback_wrapper_comm(lua_State *L)
{
    bool handled = false;
    QString name = lua_tostring(L, 1);
    QString command = lua_tostring(L, 2);
    QString params = lua_tostring(L, 3);
    for (const auto &handler : registered_on_chatcommand) {
        if (handler(name, command, params)) {
            handled = true;
            break;
        }
    }
    lua_pushboolean(L, handled);
    return 1;
}

int minetest::lua_callback_wrapper_msg(lua_State *L)
{
    bool handled = false;
    QString name = lua_tostring(L, 1);
    QString message = lua_tostring(L, 2);
    for (const auto &handler : registered_on_chatmsg) {
        if (handler(name, message)) {
            handled = true;
            break;
        }
    }
    lua_pushboolean(L, handled);
    return 1;
}

bool minetest::first_chatcomm_handler = true;
bool minetest::first_chatmsg_handler = true;

void minetest::register_on_chat_message(bool (* funcPtr)(QString&, QString&))
{
    if (first_chatmsg_handler) {
        SAVE_STACK

        lua_getglobal(L, "minetest");
        lua_getfield(L, -1, "register_on_chat_message");

        lua_pushcfunction(L, this->lua_callback_wrapper_msg);
        lua_call(L, 1, 0);

        RESTORE_STACK
        first_chatmsg_handler = false;
    }
    registered_on_chatmsg.push_front(funcPtr);
}

void minetest::register_on_chatcommand(bool (* funcPtr)(QString&, QString&, QString&))
{
    if (first_chatcomm_handler) {
        SAVE_STACK

        lua_getglobal(L, "minetest");
        lua_getfield(L, -1, "register_on_chatcommand");

        lua_pushcfunction(L, this->lua_callback_wrapper_comm);
        lua_call(L, 1, 0);

        RESTORE_STACK
        first_chatcomm_handler = false;
    }
    registered_on_chatcommand.push_front(funcPtr);
}
