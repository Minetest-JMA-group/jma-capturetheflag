// SPDX-License-Identifier: LGPL-2.1-only
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
