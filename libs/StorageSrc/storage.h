// SPDX-License-Identifier: LGPL-2.1-only
// Copyright (c) 2023 Marko Petrović
#ifndef STORAGE_H
#define STORAGE_H
#include "minetest.h"

// Assume that Lua StorageRef object is on the top of the stack
class storage : public lua_state_class {
public:
    using lua_state_class::lua_state_class;
    lua_Integer get_int(const QString &key);
    QString get_string(const QString &key);
    bool set_int(const QString &key, const lua_Integer a);
    bool set_string(const QString &key, const QString &str);
};

#endif // STORAGE_H
