-- ranks/init.lua

ranks = {}

local registered   = {}

-- Load mod storage
local storage = minetest.get_mod_storage()

---
--- API
---

-- [local function] Get color
local function get_color(color)
	if type(color) == "table" and minetest.rgba then
		return minetest.rgba(color.r, color.g, color.b, color.a)
	elseif type(color) == "string" then
		return color
	else
		return "#ffffff"
	end
end

-- [function] Register rank
function ranks.register(name, def)
	assert(name ~= "clear", "Invalid name \"clear\" for rank")

	registered[name] = def
end

-- [function] Unregister rank
function ranks.unregister(name)
	registered[name] = nil
end

-- [function] List ranks in plain text
function ranks.list_plaintext()
	local list = ""
	for rank, i in pairs(registered) do
		if list == "" then
			list = rank
		else
			list = list..", "..rank
		end
	end
	return list
end

-- [function] Get player rank
function ranks.get_rank(name)
	if type(name) ~= "string" then
		name = minetest.get_player_by_name(name)
	end

	local rank = storage:get_string(name)
	if rank ~= "" and registered[rank] then
		return rank
	end
end

-- [function] Get rank definition
function ranks.get_def(rank)
	if not rank then
		return
	end

	return registered[rank]
end

-- [function] Set player rank
function ranks.set_rank(name, rank)
	if type(name) ~= "string" then
		name = name:get_player_name()
	end

	if registered[rank] and minetest.player_exists(name) then
		storage:set_string(name, rank)

		-- Update nametag
		-- ranks.update_nametag(name)

		return true
	end
end

-- [function] Remove rank from player
function ranks.remove_rank(name)
	if type(name) ~= "string" then
		name = name:get_player_name()
	end

	local rank = ranks.get_rank(name)
	if rank ~= nil then
		storage:set_string(name, nil)
	end
end

function ranks.get_player_prefix(name)
	local rank = ranks.get_rank(name)
	if rank then
		local def = ranks.get_def(rank)
		if def.prefix then
			local color = get_color(def.color)
			return {prefix = def.prefix, color = color}
		end
	end
	return nil
end
---
--- Registrations
---

-- [privilege] Rank
minetest.register_privilege("ranking", {
	description = "Permission to use /rank chatcommand ",
	give_to_singleplayer = false,
})

-- Assign/update rank on join player
minetest.register_on_joinplayer(function(player)
	local name = player:get_player_name()

	if ranks.get_rank(name) then
		-- Update nametag
		-- ranks.update_nametag(name)
	else
		if ranks.default then
			ranks.set_rank(name, ranks.default)
		end
	end
end)

-- [chatcommand] /set_rank
minetest.register_chatcommand("set_rank", {
	description = "Set a player's rank",
	params = "<player> <new rank> / \"list\" | username, rankname / list ranks",
	privs = {ranking = true},
	func = function(name, param)
		local param = param:split(" ")
		if #param == 0 then
			return false, "Invalid usage (see /help rank)"
		end

		if #param == 1 and param[1] == "list" then
			return true, "Available Ranks: "..ranks.list_plaintext()
		elseif #param == 2 then
			if minetest.player_exists(param[1]) == false then
					return false, "Player does not exist"
			end

			if ranks.get_def(param[2]) then
				if ranks.set_rank(param[1], param[2]) then
					if name ~= param[1] then
						minetest.chat_send_player(param[1], name.." set your rank to "..param[2])
					end

					return true, "Set "..param[1].."'s rank to "..param[2]
				else
					return false, "Unknown error while setting "..param[1].."'s rank to "..param[2]
				end
			elseif param[2] == "clear" then
				ranks.remove_rank(param[1])
				return true, "Removed rank from "..param[1]
			else
				return false, "Invalid rank (see /rank list)"
			end
		else
			return false, "Invalid usage (see /help rank)"
		end
	end,
})

-- [chatcommand] /rank
minetest.register_chatcommand("rank", {
	description = "Get a player's rank. If no player is specified, your own rank is returned.",
	params = "<name> | name of player",
	func = function(name, param)
		if param and param ~= "" then
			local rank = ranks.get_rank(param)
			if rank then
				return true, "Rank of " .. param .. ": " .. rank:gsub("^%l", string.upper)
			elseif minetest.player_exists(param) then
				return false, "Rank of " .. param .. ": No rank"
			else
				return false, "Player does not exist"
			end
		else
			local rank = ranks.get_rank(name) or "No rank"
			return true, "Your rank: " .. rank:gsub("^%l", string.upper)
		end
	end,
})

---
--- Ranks
---

-- Load default ranks
dofile(minetest.get_modpath("ranks").."/ranks.lua")

local path = minetest.get_worldpath().."/ranks.lua"
-- Attempt to load per-world ranks
if io.open(path) then
	dofile(path)
end
