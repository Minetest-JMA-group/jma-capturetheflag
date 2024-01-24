// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (c) 2023 Marko Petrović
#include "minetest.h"

QLog::QLog(minetest *functions) : QTextStream(&assembledString), functions(functions) {}
QLog::~QLog()
{
    flush();
    if (assembledString == "")
        return;
    functions->log_message("warning", assembledString.toUtf8().data());
}
