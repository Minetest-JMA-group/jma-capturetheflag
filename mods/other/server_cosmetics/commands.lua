local mods = minetest.get_mod_storage()

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

local transfer_queue = get_table(mods:get_string("transfer_queue"))
--[[
{
	[pname] = {cosmetic1, cosmetic2, ...},
	...
}
--]]

function server_cosmetics.add_transfers(pname, cosmetics)
	if transfer_queue[pname] then
		for _, cos in pairs(cosmetics) do
			if not table.indexof(transfer_queue[pname], cos) then
				table.insert(transfer_queue[pname], cos)
			end
		end
	else
		transfer_queue[pname] = cosmetics
	end
end

function server_cosmetics.save_transfer_queue()
	mods:set_string("transfer_queue", minetest.serialize(transfer_queue))
end

minetest.register_chatcommand("cosmetics", {
	description = "Manage cosmetics",
	params = "<show/s> [playername] | <give/g|take/t> <playername> <cosmetic>",
	privs = {moderator = true},
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
						return true, "Cosmetic queue for player "..playername..":\n"..table.concat(transfer_queue[playername], " |\t")
					else
						return true, "No cosmetics are queued to be given to player "..playername
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
			return false, "You need to specify a cosmetic to give"
		end

		local cosmetic = false

		for k, v in pairs(cosmetic_keys) do
			if v:match(params[3]) then
				if cosmetic then
					return false, "There are multiple cosmetics that could match "..dump(params[3])..", please be more specific"
				else
					cosmetic = cosmetic_keys[k]
				end
			end
		end

		if not cosmetic then
			return false, "Couldn't find any cosmetic matching "..dump(params[3])
		end

	-- /cosmetics give <playername> <cosmetic>
		if params[1] == "give" or params[1] == "g" then
			local player = minetest.get_player_by_name(playername)

			if not player then
				if transfer_queue[playername] then
					table.insert(transfer_queue[playername], cosmetic)

					server_cosmetics.save_transfer_queue()
				else
					transfer_queue[playername] = {cosmetic}

					server_cosmetics.save_transfer_queue()
				end

				minetest.log("action", "Queued cosmetic "..dump(cosmetic).." to be given to player "..playername..
						" next time they log in")
				return true, "Queued cosmetic "..dump(cosmetic).." to be given to player "..playername.." next time they log in"
			else
				player:get_meta():set_int(cosmetic, 1)

				minetest.log("action", "Gave cosmetic "..dump(cosmetic).." to player "..playername)
				return true, "Gave cosmetic "..dump(cosmetic).." to player "..playername
			end
	-- /cosmetics take <playername> <cosmetic>
		elseif params[1] == "take" or params[1] == "t" then
			local player = minetest.get_player_by_name(playername)

			if not player then
				if transfer_queue[playername] then
					local idx = table.indexof(transfer_queue[playername], cosmetic)

					if idx then
						table.remove(transfer_queue[playername], idx)

						if #transfer_queue[playername] <= 0 then
							transfer_queue[playername] = nil
						end

						server_cosmetics.save_transfer_queue()

						minetest.log("action", "Removed cosmetic "..dump(cosmetic).." from player "..playername.."'s cosmetic queue")
						return true, "Removed cosmetic "..dump(cosmetic).." from player "..playername.."'s cosmetic queue"
					end
				end

				return false, "Player "..playername.." is not online and the given cosmetic is not in their cosmetic queue"
			else
				local meta = player:get_meta()

				if meta:get_int(cosmetic) ~= 0 then
					meta:set_int(cosmetic, 0)

					minetest.log("action", "Took cosmetic "..dump(cosmetic).." from player "..playername)
					return true, "Took cosmetic "..dump(cosmetic).." from player "..playername
				else
					return false, "Player "..playername.." doesn't have the cosmetic "..cosmetic
				end
			end
		end

		return false
	end,
})

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

		for _, cosmetic in pairs(transfer) do
			meta:set_int(cosmetic, 1)
			minetest.log("action", "Transferred cosmetic "..dump(cosmetic).." to player "..name)
		end

		transfer_queue[name] = nil

		server_cosmetics.save_transfer_queue()

		minetest.chat_send_player(name, minetest.colorize("purple", "You have received new cosmetics!"))
	end
end)
