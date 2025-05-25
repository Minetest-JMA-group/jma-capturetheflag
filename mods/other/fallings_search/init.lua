-- The code is taken from "vector_extras" https://github.com/HybridDog/vector_extras
-- CC0, except for code copied from e.g. minetest's builtin

fallings_search = {}

local fill_3d = dofile(core.get_modpath("fallings_search") .. "/fill_3d.lua")
local moves_touch = {
	{x = -1, y = 0, z = 0},
	{x = 0, y = 0, z = 0},  -- FIXME should this be here?
	{x = 1, y = 0, z = 0},
	{x = 0, y = -1, z = 0},
	{x = 0, y = 1, z = 0},
	{x = 0, y = 0, z = -1},
	{x = 0, y = 0, z = 1},
}
local moves_near = {}
for z = -1,1 do
	for y = -1,1 do
		for x = -1,1 do
			moves_near[#moves_near+1] = {x = x, y = y, z = z}
		end
	end
end

function fallings_search.search_3d(can_go, startpos, apply_move, moves)
	local visited = {}
	local found = {}
	local function on_visit(pos)
		local vi = core.hash_node_position(pos)
		if visited[vi] then
			return false
		end
		visited[vi] = true
		local valid_pos = can_go(pos)
		if valid_pos then
			found[#found+1] = pos
		end
		return valid_pos
	end
	if apply_move == "touch" then
		apply_move = vector.add
		moves = moves_touch
	elseif apply_move == "near" then
		apply_move = vector.add
		moves = moves_near
	end
	fill_3d(on_visit, startpos, apply_move, moves)
end