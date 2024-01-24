// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (c) 2023 Marko Petrović
#ifndef MINETEST_H
#define MINETEST_H
#include <lua-5.1/lua.hpp>
#include <QString>
#include <QStringList>
#include <QTextStream>
#include <forward_list>
#include <functional>
#define INT_ERROR std::numeric_limits<lua_Integer>::min()

#define SAVE_STACK int cur_top, old_top = lua_gettop(L);

#define RESTORE_STACK     cur_top = lua_gettop(L);      \
                          lua_pop(L, cur_top-old_top);

#define chatcommand_sig bool (*)(QString&, QString&, QString&)
#define chatmsg_sig bool (*)(QString&, QString&)

void printLuaStack(lua_State* L);
void pushQStringList(lua_State *L, const QStringList &privlist);
inline bool lua_isinteger(lua_State *L, int index)
{
    return lua_type(L, index) == LUA_TNUMBER;
}

class lua_state_class {
protected:
    lua_State *L;
public:
    lua_state_class(lua_State *L);
    lua_state_class();
    void set_state(lua_State *L);
};

struct cmd_ret {
    bool success;
    QString ret_msg;
};

struct cmd_def {
    const QStringList& privs;
    const QString& description;
    const QString& params;
    int (*func)(lua_State* L);
};

// Typically a global object
class minetest : public lua_state_class {
private:
    void *StorageRef = nullptr;
    static bool first_chatmsg_handler;
    static bool first_chatcomm_handler;
    static void create_command_deftable(lua_State *L, const struct cmd_def &def);
    static int lua_callback_wrapper_msg(lua_State *L);
    static int lua_callback_wrapper_comm(lua_State *L);
public:
    static std::forward_list<chatmsg_sig> registered_on_chatmsg;
    static std::forward_list<chatcommand_sig> registered_on_chatcommand;
    using lua_state_class::lua_state_class;
    minetest();
    void log_message(const QString &level, const QString &msg);
    void chat_send_all(const QString &msg);
    void chat_send_player(const QString &playername, const QString &msg);
    void get_mod_storage(); // Leaves StorageRef on the stack top

    void register_on_chat_message(chatmsg_sig);
    void register_on_chatcommand(chatcommand_sig);
    void dont_call_this_use_macro_reg_chatcommand(const QString &comm, const struct cmd_def &def);
};

#define register_chatcommand(comm, privs, description, params, func)   \
dont_call_this_use_macro_reg_chatcommand(comm, cmd_def{privs, description, params, [](lua_State *L) -> int {    \
    QString name = lua_tostring(L, 1);  \
    QString cmdparams = lua_tostring(L, 2); \
    struct cmd_ret ret = func(name, cmdparams);   \
    lua_pushboolean(L, ret.success);    \
    lua_pushstring(L, ret.ret_msg.toUtf8().data()); \
    return 2;   \
}})

/* Usually one would do something like
 * #define qLog QLog(&m)
 * where m is of type minetest and then use qLog << "Text" for logging.
*/
class QLog : public QTextStream {
private:
    QString assembledString;
    minetest *functions;
public:
    QLog(minetest *functions);
    ~QLog();
};

#endif // MINETEST_H
