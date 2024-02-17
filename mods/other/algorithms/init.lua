-- SPDX-License-Identifier: GPL-3.0-or-later
-- Copyright (c) 2023 Marko Petrović

algorithms = {}
-- Register dummy functions, provided from C++
algorithms.countCaps = function(string) return 0 end
algorithms.lower = function(string) return string end
algorithms.upper = function(string) return string end
local already_loaded = {}
local c_mods = {}
local ie = minetest.request_insecure_environment()
local list = minetest.settings:get("secure.c_mods") or ""

for word in list:gmatch("[^,%s]+") do
	c_mods[word] = true
end

-- Load the shared library mylibrary.so in the mod folder of the calling mod
algorithms.load_library = function()
	local modname = minetest.get_current_modname()

	if not c_mods[modname] then
		minetest.log("["..modname.."]: Attempted to load shared object file without permission!")
		return false
	end

	if already_loaded[modname] then
		return true
	end
	already_loaded[modname] = true

	local MP = minetest.get_modpath(modname)
	local libinit, err = ie.package.loadlib(MP.."/mylibrary.so", "luaopen_mylibrary")
	if not libinit and err then
		minetest.log("["..modname.."]: Failed to load shared object file")
		minetest.log("["..modname.."]: "..err)
		return false
	end

	libinit()
	return true
end
algorithms.load_library()

local unit_to_secs = {
	s = 1, m = 60, h = 3600,
	D = 86400, W = 604800, M = 2592000, Y = 31104000,
	[""] = 1,
}

-- Convert input using time labels (s, m, h, etc) into seconds
algorithms.parse_time = function(t)
	if type(t) ~= "string" then
		return nil
	end
	local secs = nil
	for num, unit in t:gmatch("(%d+)([smhDWMY]?)") do
		if not secs then
			secs = 0
		end
		secs = secs + (tonumber(num) * (unit_to_secs[unit] or 1))
	end
	return secs
end

local function checkPlural(timeNum, timeStr)
	if timeNum == 1 then
		return timeStr
	end
	return timeStr.."s"
end

-- Convert time in seconds to rounded human-readable string
algorithms.time_to_string = function(sec)
	if type(sec) ~= "number" then
		return ""
	end
	sec = math.floor(sec)

	local min = math.floor(sec / 60)
	sec = sec % 60
	local hour = math.floor(min / 60)
	min = min % 60
	local day = math.floor(hour / 24)
	hour = hour % 24
	local month = math.floor(day / 30)
	day = day % 30
	local year = math.floor(month / 12)
	month = month % 12

	if year > 0 then
		return "more than a year"
	end
	if month > 0 then
		return tostring(month) .. " " .. checkPlural(month, "month")
	end
	if day > 0 then
		return tostring(day) .. " " .. checkPlural(day, "day")
	end
	if hour > 0 then
		return tostring(hour) .. " " .. checkPlural(hour, "hour")
	end
	if min > 0 then
		return tostring(min) .. " " .. checkPlural(min, "minute")
	end
	return tostring(sec) .. " " .. checkPlural(sec, "second")
end

-- Separate the string into n-grams
algorithms.nGram = function(string, window_size)
	if type(string) ~= "string" or type(window_size) ~= "number" then
		return {}
	end
	window_size = math.floor(window_size) - 1
	local string_len = utf8_simple.len(string)
	if window_size <= string_len then
		return {string}
	end
	local ret = {}
	for i = 1, string_len - window_size do
		table.insert(ret, utf8_simple.sub(string, i, i+window_size))
	end
	return ret
end

-- Create a matrix of integers with dimensions n x m
algorithms.createMatrix = function(n, m)
	if type(n) ~= "number" or type(m) ~= "number" then
		return nil
	end
	n = math.floor(n)
	m = math.floor(m)

	local matrix = {}
	for i = 1, n do
		matrix[i] = {}
		for j = 1, m do
			matrix[i][j] = 0
		end
	end
	return matrix
end

-- Matrix to human-readable string
algorithms.matostr = function(matrix)
	if type(matrix) ~= "table" then
		return "Error: algorithms.matostr didn't receive a matrix"
	end

	local pr = ""
	for _, row in ipairs(matrix) do
		if type(row) ~= "table" then
			return "Error: algorithms.matostr didn't receive a matrix"
		end
		for _, elem in ipairs(row) do
			pr = pr..tostring(elem) .. " "
		end
		pr = pr.."\n"
	end
	return pr
end

-- Longest Common Substring
algorithms.lcs = function(string1, string2)
	if type(string1) ~= "string" or type(string2) ~= "string" then
		return nil
	end
	local len1 = utf8_simple.len(string1)
	local len2 = utf8_simple.len(string2)

	matrix = algorithms.createMatrix(len1+1, len2+1)
	for i = 2, len1 + 1 do
		for j = 2, len2 + 1 do
			if utf8_simple.sub(string1,i-1,i-1) == utf8_simple.sub(string2,j-1,j-1) then
				matrix[i][j] = matrix[i-1][j-1] + 1
			else
				matrix[i][j] = math.max(matrix[i-1][j], matrix[i][j-1])
			end
		end
	end

	local i = len1 + 1
	local j = len2 + 1
	local res = ""
	while matrix[i][j] ~= 0 do
		local oldi = i
		local oldj = j
		while matrix[oldi][oldj] == matrix[i][j] do
			i = i - 1
		end
		i = i + 1	-- Go back to the last pos where condition was true
		while matrix[oldi][oldj] == matrix[i][j] do
			j = j - 1
		end
		j = j + 1	-- Go back to the last pos where condition was true

		res = res..utf8_simple.sub(string1, i-1, i-1)
		i = i - 1
		j = j - 1
	end
	
	return utf8_simple.reverse(res)
end
