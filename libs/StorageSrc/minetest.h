// SPDX-License-Identifier: LGPL-2.1-only
// Copyright (c) 2023 Marko Petrović
#ifndef MINETEST_H
#define MINETEST_H
#include <lua-5.1/lua.hpp>
#include <QString>
#include <QTextStream>
#include <forward_list>
#define INT_ERROR std::numeric_limits<lua_Integer>::min()

#define SAVE_STACK int cur_top, old_top = lua_gettop(L);

#define RESTORE_STACK     cur_top = lua_gettop(L);      \
                          lua_pop(L, cur_top-old_top);

#define chatcommand_sig bool (*)(QString&, QString&, QString&)
#define chatmsg_sig bool (*)(QString&, QString&)

void printLuaStack(lua_State* L);
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

// Typically a global object
class minetest : public lua_state_class {
private:
    void *StorageRef = nullptr;
    static bool first_chatmsg_handler;
    static bool first_chatcomm_handler;
    static std::forward_list<chatmsg_sig> registered_on_chatmsg;
    static std::forward_list<chatcommand_sig> registered_on_chatcommand;
    static int lua_callback_wrapper_msg(lua_State *L);
    static int lua_callback_wrapper_comm(lua_State *L);
public:
    using lua_state_class::lua_state_class;
    minetest();
    void log_message(const QString &level, const QString &msg);
    void chat_send_all(const QString &msg);
    void chat_send_player(const QString &playername, const QString &msg);
    void get_mod_storage(); // Leaves StorageRef on the stack top

    void register_on_chat_message(chatmsg_sig);
    void register_on_chatcommand(chatcommand_sig);
};

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
