---@meta

--- Extensions to standard Lua libraries provided by Luanti

--- Split a string into parts.
---@param separator string
---@param include_empty? boolean (default false)
---@param max_splits? integer (negative = unlimited, default -1)
---@param sep_is_pattern? boolean (default false)
---@return string[]
function string:split(separator, include_empty, max_splits, sep_is_pattern) end

--- Trim whitespace from both ends.
---@return string
function string:trim() end

--- Deep copy a table (strips metatables).
---@param t table
---@return table
function table.copy(t) end

--- Deep copy a table, preserving metatables.
---@param t any (non‑table values are returned as‑is)
---@return any
function table.copy_with_metatables(t) end

--- Find the smallest numerical index containing a value.
---@param list table
---@param val any
---@return integer|nil
function table.indexof(list, val) end

--- Find a key by value.
---@param t table
---@param val any
---@return any|nil
function table.keyof(t, val) end

--- Append all values from src to dest (array part).
---@param dest table
---@param src table
function table.insert_all(dest, src) end

--- Swap keys and values.
---@param t table
---@return table
function table.key_value_swap(t) end

--- Shuffle elements in a table in place.
---@param t table
---@param from? integer (default 1)
---@param to? integer (default #t)
---@param random_func? fun(min:integer, max:integer):integer (default math.random)
function table.shuffle(t, from, to, random_func) end

--- Get the hypotenuse of a right triangle.
---@param x number
---@param y number
---@return number
function math.hypot(x, y) end

--- Get the sign of a number.
---@param x number
---@param tolerance? number (default 0)
---@return -1|0|1
function math.sign(x, tolerance) end

--- Compute factorial.
---@param x integer
---@return integer
function math.factorial(x) end

--- Round to nearest integer (away from zero at 0.5).
---@param x number
---@return integer
function math.round(x) end

--- Check if a number is finite (not inf or NaN).
---@param x number
---@return boolean
function math.isfinite(x) end