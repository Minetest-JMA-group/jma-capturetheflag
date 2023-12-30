-- SPDX-License-Identifier: LGPL-2.1-only
-- Copyright (c) 2023 Marko Petrović

algorithms = {}

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
	if not string1 or not string2 or type(string1) ~= "string" or type(string2) ~= "string" then
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
