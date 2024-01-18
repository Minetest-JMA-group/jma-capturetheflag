// SPDX-License-Identifier: LGPL-2.1-only
// Copyright (c) 2023 Marko Petrović
#ifndef MINETEST_H
#define MINETEST_H
#include <lua-5.1/lua.hpp>
#include <QString>
#include <QTextStream>
#define INT_ERROR std::numeric_limits<lua_Integer>::min()

#define SAVE_STACK int cur_top, old_top = lua_gettop(L);

#define RESTORE_STACK     cur_top = lua_gettop(L);      \
                          lua_pop(L, cur_top-old_top);

void printLuaStack(lua_State* L);
inline bool lua_isinteger(lua_State *L, int index)
{
    return lua_type(L, index) == LUA_TNUMBER;
}

class minetest {
protected:
    lua_State *L;
    void *StorageRef = nullptr;
public:
    minetest(lua_State *L);
    minetest();
    void set_state(lua_State *L);
    void log_message(const QString &level, const QString &msg);
    void chat_send_all(const QString &msg);
    void chat_send_player(const QString &playername, const QString &msg);
    void get_mod_storage(); // Leaves StorageRef on the stack top
};

class QLog : public QTextStream {
private:
    QString assembledString;
    minetest *functions;
public:
    QLog(minetest *functions);
    ~QLog();
};

#endif // MINETEST_H
