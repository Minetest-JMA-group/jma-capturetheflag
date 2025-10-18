-- Returns a function, this function returns f or not f based on a boolean
local function flip(f, bool)
	if bool then return function(a,b) return not f(a,b) end end
	return function(a,b) return f(a,b) end
end

local function sort_by_alphabetical(a, b)
	local a_type = ctf_jma_achieves.registered_achievements[a].type
	local b_type = ctf_jma_achieves.registered_achievements[b].type
	if (a_type == "bronze" and b_type ~= "bronze") or (a_type == "silver" and b_type == "gold") then
		return true
	elseif a_type ~= b_type then
		return false
	end
	local a_title = ctf_jma_achieves.registered_achievements[a].name
	local b_title = ctf_jma_achieves.registered_achievements[b].name
	return a_title < b_title
end
local function sort_by_mixed_alphabetical(a, b)
	local a_title = ctf_jma_achieves.registered_achievements[a].name
	local b_title = ctf_jma_achieves.registered_achievements[b].name
	return a_title < b_title
end

local function sort_by_order(a, b)
	local a_order = ctf_jma_achieves.registered_achievements[a].order or -math.huge
	local b_order = ctf_jma_achieves.registered_achievements[b].order or -math.huge
	if a_order == b_order then
		return sort_by_alphabetical(a, b)
	end
	return a_order < b_order
end

local function sort_by_rarity(a, b)
	local a_percent = ctf_jma_achieves.achievement_complete_percent_cache[a].percent
	local b_percent = ctf_jma_achieves.achievement_complete_percent_cache[b].percent
	if a_percent == b_percent then
		return sort_by_order(a, b)
	end
	return a_percent > b_percent
end

return function(sort_table, name)
	local sorted_achieves = {}
	for id, _ in pairs(ctf_jma_achieves.registered_achievements) do
		local unlocked = ctf_jma_achieves.get_achievement_unlocked(name, id)
		
		if not (sort_table.filter == "unlocked" and not unlocked
		   or sort_table.filter == "locked" and unlocked) then
			table.insert(sorted_achieves, id)
		end
	end
	
	if sort_table.sort == 3 then
		table.sort(sorted_achieves, flip(sort_by_rarity, sort_table.flip))
	elseif sort_table.sort == 2 then
		table.sort(sorted_achieves, flip(sort_by_alphabetical, sort_table.flip))
	elseif sort_table.sort == 4 then
		table.sort(sorted_achieves, flip(sort_by_mixed_alphabetical, sort_table.flip))
	else
		table.sort(sorted_achieves, flip(sort_by_order, sort_table.flip))
	end
	
	return sorted_achieves
end