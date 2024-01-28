// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (c) 2023 Marko Petrović
#include <minetest.h>

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

QString minetest::get_current_modname()
{
    SAVE_STACK

    lua_getglobal(L, "minetest");
    lua_getfield(L, -1, "get_current_modname");

    lua_call(L, 0, 1);
    QString res = lua_tostring(L, -1);

    RESTORE_STACK
    return res;
}

QString minetest::get_modpath(const QString &modname)
{
    SAVE_STACK

    lua_getglobal(L, "minetest");
    lua_getfield(L, -1, "get_modpath");

    lua_pushstring(L, modname.toUtf8().data());
    lua_call(L, 1, 1);
    QString res = lua_tostring(L, -1);

    RESTORE_STACK
    return res;
}

QString minetest::get_worldpath()
{
    SAVE_STACK

    lua_getglobal(L, "minetest");
    lua_getfield(L, -1, "get_worldpath");

    lua_call(L, 0, 1);
    QString res = lua_tostring(L, -1);

    RESTORE_STACK
    return res;
}

void minetest::register_privilege(const QString &name, const QString &definition)
{
    SAVE_STACK

    lua_getglobal(L, "minetest");
    lua_getfield(L, -1, "register_privilege");

    lua_pushstring(L, name.toUtf8().data());
    lua_pushstring(L, definition.toUtf8().data());
    lua_call(L, 2, 0);

    RESTORE_STACK
}

void minetest::get_mod_storage()
{
    if (is_top_modstorage())
        return;

    if (StorageRef == nullptr) {
        lua_getglobal(L, "minetest");
        lua_getfield(L, -1, "get_mod_storage");
        lua_remove(L, -2);
        lua_call(L, 0, 1);
        void *retrievedPointer = lua_touserdata(L, -1);
        StorageRef = *(void **)retrievedPointer;

        luaL_newmetatable(L, "StorageRef_nogc");
        luaL_getmetatable(L, "StorageRef");
        copyLuaTable(L, -1, -2);
        lua_pushnil(L);
        lua_setfield(L, -3, "__gc");
        lua_pop(L, 1);  // Pop the original StorageRef metatable
        lua_setmetatable(L, -2);    // Set new StorageRef_nogc to modstorage userobject
    }
    else {
        *(void **)(lua_newuserdata(L, sizeof(void *))) = StorageRef;
        luaL_getmetatable(L, "StorageRef_nogc");
        lua_setmetatable(L, -2);
    }
}

void minetest::pop_modstorage()
{
    if (is_top_modstorage())
        lua_pop(L, 1);
}

minetest::~minetest()
{
    // Construct a StorageRef object WITH __gc method to collect it
    if (StorageRef != nullptr && L != nullptr) {
        SAVE_STACK
        *(void **)(lua_newuserdata(L, sizeof(void *))) = StorageRef;
        luaL_getmetatable(L, "StorageRef");
        lua_setmetatable(L, -2);
        RESTORE_STACK
    }
}

bool minetest::is_top_modstorage()
{
    if (lua_gettop(L) == 0)
        return false;
    if (!lua_isuserdata(L, -1))
        return false;
    return *(void **)lua_touserdata(L, -1) == StorageRef;
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

std::forward_list<chatmsg_sig> minetest::registered_on_chatmsg = std::forward_list<chatmsg_sig>();
std::forward_list<chatcommand_sig> minetest::registered_on_chatcommand = std::forward_list<chatcommand_sig>();

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

void pushQStringList(lua_State *L, const QStringList &privlist) {
    lua_newtable(L);
    for (const QString &priv : privlist) {
        lua_pushboolean(L, true);
        lua_setfield(L, -2, priv.toUtf8().data());
    }
}

void minetest::create_command_deftable(lua_State *L, const struct cmd_def &def)
{
    lua_newtable(L);

    lua_pushstring(L, def.description.toUtf8().data());
    lua_setfield(L, -2, "description");

    lua_pushstring(L, def.params.toUtf8().data());
    lua_setfield(L, -2, "params");

    pushQStringList(L, def.privs);
    lua_setfield(L, -2, "privs");

    lua_pushcfunction(L, def.func);
    lua_setfield(L, -2, "func");
}

void minetest::dont_call_this_use_macro_reg_chatcommand(const QString &comm, const struct cmd_def &def)
{
    SAVE_STACK

    lua_getglobal(L, "minetest");
    lua_getfield(L, -1, "register_chatcommand");
    lua_pushstring(L, comm.toUtf8().data());
    create_command_deftable(L, def);
    lua_call(L, 2, 0);

    RESTORE_STACK
}
