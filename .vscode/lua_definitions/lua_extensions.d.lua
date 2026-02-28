---@meta

--- Extensions to standard Lua libraries provided by Luanti.

--- Splits a string into parts using a separator.
---@param separator string
---@param include_empty? boolean (default false)
---@param max_splits? integer (negative = unlimited, default -1)
---@param sep_is_pattern? boolean (default false)
---@return string[]
function string:split(separator, include_empty, max_splits, sep_is_pattern) end

--- Trims whitespace from both ends of a string.
---@return string
function string:trim() end

--- Deep copies a table (strips metatables).
---@param t table
---@return table
function table.copy(t) end

--- Deep copies a table, preserving metatables.
---@param t any (non‑table values are returned as‑is)
---@return any
function table.copy_with_metatables(t) end

--- Returns the smallest numerical index containing a value.
---@param list table
---@param val any
---@return integer|nil
function table.indexof(list, val) end

--- Returns a key containing the given value.
---@param t table
---@param val any
---@return any|nil
function table.keyof(t, val) end

--- Appends all values from src to dest (array part).
---@param dest table
---@param src table
function table.insert_all(dest, src) end

--- Swaps keys and values.
---@param t table
---@return table
function table.key_value_swap(t) end

--- Shuffles elements in a table in place.
---@param t table
---@param from? integer (default 1)
---@param to? integer (default #t)
---@param random_func? fun(min:integer, max:integer):integer (default math.random)
function table.shuffle(t, from, to, random_func) end

--- Returns the hypotenuse of a right triangle.
---@param x number
---@param y number
---@return number
function math.hypot(x, y) end

--- Returns the sign of a number (-1, 0, or 1).
---@param x number
---@param tolerance? number (default 0)
---@return -1|0|1
function math.sign(x, tolerance) end

--- Returns the factorial of x.
---@param x integer
---@return integer
function math.factorial(x) end

--- Rounds a number to the nearest integer (away from zero at 0.5).
---@param x number
---@return integer
function math.round(x) end

--- Returns true if x is finite (not inf or NaN).
---@param x number
---@return boolean
function math.isfinite(x) end

---@class string
---@field trim fun(self:string): string
---@field split fun(self:string, separator:string, include_empty?:boolean, max_splits?:integer, sep_is_pattern?:boolean): string[]