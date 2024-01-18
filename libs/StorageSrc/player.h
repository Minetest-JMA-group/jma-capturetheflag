// SPDX-License-Identifier: LGPL-2.1-only
// Copyright (c) 2023 Marko Petrović
#ifndef PLAYER_H
#define PLAYER_H
#include "minetest.h"

// Assume that Player object is on the top of the stack
class player : public lua_state_class {
public:
    using lua_state_class::lua_state_class;
    bool get_meta(); // Leaves PlayerMetaRef on the stack top, can be used with storage class
    QString get_player_name();
};

#endif // PLAYER_H
