---@meta

--- Extensions to standard Lua libraries provided by Luanti

--- Splits a string into parts using a separator.
---@param s string
---@param sep string
---@param plain? boolean (if true, treat sep as plain text, not pattern)
---@param max_splits? integer
---@param include_empty? boolean (if true, include empty fields)
---@return string[]
function string.split(s, sep, plain, max_splits, include_empty) end

--- Returns the index of a value in the array part of a table.
---@param t table
---@param value any
---@return integer|nil
function table.indexof(t, value) end

--- Shallow copy of a table.
---@param t table
---@return table
function table.copy(t) end

--- Returns true if the value is present in the array part of the table.
---@param t table
---@param value any
---@return boolean
function table.contains(t, value) end

--- Inserts all elements from src into dest (as array).
---@param dest table
---@param src table
function table.insert_all(dest, src) end

--- Returns an array of all keys in the table.
---@param t table
---@return any[]
function table.keys(t) end

--- Returns an array of all values in the table.
---@param t table
---@return any[]
function table.values(t) end

--- Clamps a value between min and max.
---@param value number
---@param min number
---@param max number
---@return number
function math.clamp(value, min, max) end