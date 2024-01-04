-- SPDX-License-Identifier: LGPL-2.1-only
-- Copyright (c) 2023 Marko Petrović

algorithms = {}
local MP = minetest.get_modpath(minetest.get_current_modname())
local ie = minetest.request_insecure_environment()
local libinit, err = ie.package.loadlib(MP.."/mylibrary.so", "luaopen_mylibrary")
local mylibrary

if not libinit and err then
	minetest.log("[algorithms]: Failed to load shared object file")
	minetest.log("[algorithms]: "..err)
	mylibrary = {}
else
	mylibrary = libinit()
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

algorithms.countCaps = mylibrary.countCaps or function(string) return 0 end

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
