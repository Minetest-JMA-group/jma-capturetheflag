local mods = minetest.get_mod_storage()
local TRANSFER_QUEUE_VERSION = 2

local function get_table(x)
	if x and x ~= "" then
		return minetest.deserialize(x)
	else
		return {}
	end
end

-- Set what cosmetics we can transfer, and how to find them

local cosmetic_keys = {}

for name, data in pairs(server_cosmetics.cosmetics.entity_cosmetics) do
	local date = data._date_start
	if date then
		while data[tostring(date)] do
			table.insert(cosmetic_keys, "server_cosmetics:entity:"..name..":"..tostring(date))

			date = date + 1
		end
	else
		for k, v in pairs(data) do
			if k:sub(1, 1) ~= "_" then
				table.insert(cosmetic_keys, "server_cosmetics:entity:"..name..":"..k)
			end
		end
	end
end

for name, data in pairs(server_cosmetics.cosmetics.headwear) do
	for k, v in pairs(data) do
		if k:sub(1, 1) ~= "_" then
			table.insert(cosmetic_keys, "server_cosmetics:headwear:sunglasses:"..k)
		end
	end
end

minetest.log("action", "Loaded cosmetics: "..dump(cosmetic_keys))

-- Register the priv and its commmand

minetest.register_privilege("cosmetic_manager", {
	description = "Allows doing things like transferring/giving cosmetics",
})

local queue_version = mods:get_int("transfer_queue_version")
local transfer_queue = get_table(mods:get_string("transfer_queue"))
--[[
{
	[pname] = {[cosmetic1] = "give", [cosmetic2] = "take", ...},
	...
}
--]]

function server_cosmetics.save_transfer_queue()
	mods:set_string("transfer_queue", minetest.serialize(transfer_queue))
end

-- Convert older queue formats. Needs to be updated whenever the format is changed
if queue_version <= 1 then
	local dir = minetest.get_worldpath().."/server_cosmetics/"

	minetest.mkdir(dir)

	local f, err = io.open(dir.."transfer_queue_backup_v1.txt", "w")

	if f then
		f:write(minetest.serialize(transfer_queue))
	else
		minetest.log("error", err)
	end

	f:close()

	for pname, list in pairs(transfer_queue) do
		local new = {}
		for _, cosmetic in pairs(list) do
			new[cosmetic] = "give"
		end
		transfer_queue[pname] = new
	end

	server_cosmetics.save_transfer_queue()

	mods:set_int("transfer_queue_version", TRANSFER_QUEUE_VERSION)
end

function server_cosmetics.add_transfers(pname, cosmetics)
	if not transfer_queue[pname] then
		transfer_queue[pname] = {}
	end

	for cos, action in pairs(cosmetics) do
		if action == "give" or action == "take" then
			transfer_queue[pname][cos] = action
		else -- transfer queue v1
			transfer_queue[pname][action] = "give"
		end
	end
end

minetest.register_chatcommand("cosmetics", {
	description = "Manage cosmetics",
	params = "<show/s> [playername] | <give/g|take/t> <playername> <cosmetic>",
	privs = {cosmetic_manager = true},
	func = function(name, params)
		params = string.split(params, "%s", false, 2, true)

		local playername = params[2]

		if not params[1] then return false end

	-- /cosmetics show [playername]
		if params[1] == "show" or params[1] == "s" then
			if not playername then
				return true, "Available cosmetics:\n"..table.concat(cosmetic_keys, " |\t")
			else
				local player = minetest.get_player_by_name(playername)

				if player then
					local meta = player:get_meta()
					local out = {}

					for k, v in pairs(cosmetic_keys) do
						if meta:get_int(v) ~= 0 then
							table.insert(out, v)
						end
					end

					if #out > 0 then
						return true, "Cosmetics of player "..playername..":\n"..table.concat(out, " |\t")
					else
						return true, "Player has no managable cosmetics"
					end
				else
					if transfer_queue[playername] then
						return true, "Cosmetic queue for player "..playername..":\n"..dump(transfer_queue[playername])
					else
						return true, "Player "..playername.." has no cosmetics queued"
					end
				end
			end
		end

	--
	--- /cosmetics <give | take> <playername> <cosmetic>
	--

	-- Verify a player was given
		if not playername then
			return false, "You need to supply a player to manage the cosmetics of"
		end

	-- Verify a valid cosmetic param was given
		if not params[3] then
			return false, "You need to specify a cosmetic to give/take"
		end

		local cosmetic
		local matches = {}
		for k, v in pairs(cosmetic_keys) do
			if v:match(params[3]) then
				table.insert(matches, cosmetic_keys[k])
			end
		end

		if #matches <= 0 then
			return false, "Couldn't find any cosmetic matching " .. dump(params[3])
		elseif #matches > 1 then
			return false, "There are multiple cosmetics that match " .. dump(params[3]) .. ", please be more specific:\n\t" ..
					minetest.colorize("cyan", table.concat(matches, "\n\t"))
		else
			cosmetic = matches[1]
		end

	-- /cosmetics <give/take> <playername> <cosmetic>
		local action = "given to"
		local action_past = {"Gave", "to"}
		if params[1] == "give" or params[1] == "g" then
			params[1] = "give"
		elseif params[1] == "take" or params[1] == "t" then
			params[1] = "take"
			action = "taken from"
			action_past = {"Took", "from"}
		end

		if params[1] == "give" or params[1] == "take" then
			local player = minetest.get_player_by_name(playername)

			if not player then
				if transfer_queue[playername] and
				transfer_queue[playername][cosmetic] and params[1] ~= transfer_queue[playername][cosmetic] then
					local msg = "Removed cosmetic "..dump(cosmetic).." from player "..playername.."'s cosmetic queue"

					transfer_queue[playername][cosmetic] = nil

					if not next(transfer_queue[playername]) then
						transfer_queue[playername] = nil
					end

					server_cosmetics.save_transfer_queue()

					minetest.log("action", msg)
					return true, msg
				end

				if not transfer_queue[playername] then
					transfer_queue[playername] = {}
				end

				transfer_queue[playername][cosmetic] = params[1]
				server_cosmetics.save_transfer_queue()

				minetest.log("action", "Queued cosmetic "..dump(cosmetic).." to be "..action.." player "..playername..
						" next time they log in")
				return true, "Queued cosmetic "..dump(cosmetic).." to be "..action.." player "..playername.." next time they log in"
			else
				player:get_meta():set_int(cosmetic, (params[1] == "give") and 1 or 0)

				minetest.log("action", action_past[1].." cosmetic "..dump(cosmetic).." "..action_past[2].." player "..playername)
				return true, action_past[1].." cosmetic "..dump(cosmetic).." "..action_past[2].." player "..playername
			end
		end

		return false
	end,
})

-- TODO:
-- minetest.register_chatcommand("transfer_cosmetics", {
-- 	description = "Transfer cosmetics from one player to another",
-- 	params = "<from name> <to name>",
-- 	privs = {cosmetic_manager = true},
-- 	func = function(name, params)

-- 	end,
-- })

-- Handle cosmetic transfers
minetest.register_on_joinplayer(function(player)
	local name = player:get_player_name()
	local transfer = transfer_queue[name]

	if transfer then
		local meta = player:get_meta()
		local gave_count = 0
		local took_count = 0

		for cosmetic, action in pairs(transfer) do
			local set_to = (action == "give") and 1 or 0
			local old = meta:get_int(cosmetic)

			if old ~= set_to then
				meta:set_int(cosmetic, set_to)

				if action == "give" then
					gave_count = gave_count + 1
					minetest.log("action", "Transferred cosmetic "..dump(cosmetic).." to player "..name)
				else
					took_count = took_count + 1
					minetest.log("action", "Took cosmetic "..dump(cosmetic).." from player "..name)
				end
			end
		end

		transfer_queue[name] = nil

		server_cosmetics.save_transfer_queue()

		if gave_count + took_count > 0 then
			minetest.chat_send_player(name, minetest.colorize("purple", (
				"Your cosmetics have been changed! %d added, %d removed"
			):format(gave_count, took_count)))
		end
	end
end)
