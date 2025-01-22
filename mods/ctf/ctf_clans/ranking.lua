ctf_clans.ranking = {}
local storage = minetest.get_mod_storage()
local floor = math.floor
local multipler = 500
local ranking_key = "ranking:%d"
local rankings = {}
local max_ranked_indices = 100

local function load_rankings()
	for i = 1, max_ranked_indices do
		local key = string.format(ranking_key, i)
		if storage:contains(key) then
			local ranking_data = minetest.deserialize(storage:get_string(key))
			if ranking_data then
				rankings[i] = ranking_data
			end
		else
			break
		end
	end

	print(dump2(rankings))
end

local function save_rankings()
	for i, v in pairs(rankings) do
		storage:set_string(string.format(ranking_key, i), minetest.serialize(v))
		minetest.debug("ranking saved: " .. v.id)
	end
end


local function get_level_from_score(score)
	if not score then return 1 end
	local a = 0
	local x = 1
	while(floor(a / 4) <= score) do
		a = a + floor( x + multipler * (2 ^ ( x / 7 ) ))
		x = x + 1
	end
	return x - 1
end

local function get_current_ranking_index(id)
	for i = 1, max_ranked_indices do
		if rankings[i] and rankings[i].id == id then
			return i
		end
	end
	return nil
end

local function update_ranking(id)
    local our_index = get_current_ranking_index(id)
    if not our_index or not rankings[our_index] then return end

    local our_score = rankings[our_index].score
    local target_index = our_index

    while target_index < max_ranked_indices and rankings[target_index + 1] do
        if rankings[target_index + 1].score < our_score then
            break
        end
        target_index = target_index + 1
    end

    while target_index > 1 and rankings[target_index - 1] do
        if rankings[target_index - 1].score > our_score then
            break
        end
        target_index = target_index - 1
    end

    if target_index ~= our_index then
        local copy = rankings[our_index]
        table.remove(rankings, our_index)
        table.insert(rankings, target_index, copy)

        minetest.debug(string.format("Clan with ID %d moved: new location = %d (was %d)", id, target_index, our_index))
    end

end

function ctf_clans.ranking.add_score(id, new_score)
	if ctf_clans.is_clan_exist(id) then
		local r_idx = get_current_ranking_index(id)
		local score = r_idx and rankings[r_idx].score or 0

		local old_rank = get_level_from_score(score)
		score = score + new_score
		local new_rank = get_level_from_score(score)

		if new_rank ~= old_rank then
			local this_clan = ctf_clans.get_clan(id)
			print("Clan " .. this_clan.clan_name .. " has risen in the ranking to " .. new_rank .. " place")
		end

		if not r_idx then
			table.insert(rankings, {id = id, score = score})
		else
			rankings[r_idx].score = score
		end

		update_ranking(id)
		print(dump2(rankings))
		save_rankings()
	end
end

load_rankings()

minetest.register_chatcommand("clan_ranking", {
	func = function()
		local message = "Clan Ranking:\n"
		if #rankings > 0 then
			message = message .. " # | ID | Level\n"
			message = message .. " ---|-----|--------\n"
			for i, r in ipairs(rankings) do
				message = message .. string.format(" %2d | %3d | %5d\n", i, r.id, get_level_from_score(r.score))
			end
		else
			message = message .. "No ranking clan data"
		end
		return true, message
	end
})

minetest.register_chatcommand("aclans_add_score",{
	description = "",
    privs = {server = true, clans = true},
	params = "",
	func = function(name, params)
		local args = params:split(" ")
		local id = tonumber(args[1])
		local new_score = tonumber(args[2])
		if not id or not new_score then
			return false, "invalid usage."
		end
		print(id, new_score)
		if ctf_clans.storage.is_clan_data_exist(id) then
			ctf_clans.ranking.add_score(id, new_score)
			return true, "Ok"
		end
	end
})
