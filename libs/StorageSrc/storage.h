// SPDX-License-Identifier: LGPL-2.1-only
// Copyright (c) 2023 Marko Petrović
#ifndef STORAGE_H
#define STORAGE_H
#include "minetest.h"

// Assume that Lua table storage is on the top of the stack
class storage : public minetest {
public:
    using minetest::minetest;
    lua_Integer get_int(const QString &key);
    QString get_string(const QString &key);
    bool set_int(const QString &key, lua_Integer a);
    bool set_string(const QString &key, const QString &str);
};

#endif // STORAGE_H
