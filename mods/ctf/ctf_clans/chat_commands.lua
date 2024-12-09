-- Admin chat commands
-- These commands can break something if used incorrectly, be careful

minetest.register_privilege("clans", {
	description = "Clans management",
    give_to_admin = true,
})

minetest.register_chatcommand("aclans_make", {
    description = "Create a new clan",
    privs = {clans = true},
    params = "<player_name> <clan_name> <title> <color> <prefix>",
    func = function(name, param)
		if ctf_clans.get_clan_id(name) then
			return false, "Unable to create clan because you are already in another clan"
		end

		local args = param:split(" ")
        if #args < 4 then
            minetest.chat_send_player(name, "Insufficient parameters")
            return false
        end

		if not (args[1] or minetest.get_player_by_name(args[1])) then
			return false, "Player is offline or player name is not provided"
		end

        local def = {
            owner = args[1],
            clan_name = args[2],
            title = args[3],
            color = args[4],
            prefix = args[5]
        }

        -- Create a new clan with the provided parameters
        local id = ctf_clans.create(name, def)
        if id then
            return true, "Clan created successfully! ID: " .. id
        else
            return false,  "Failed to create the clan."
        end
    end
})

minetest.register_chatcommand("aclans_kick",{
	description = "Kick player from the clan",
    privs = {clans = true},
	params = "<Player Name>",
	func = function(name, param)
		if param == "" then
			return false, "No player name provided"
		end

		if not minetest.player_exists(param) then
			return false, "The player does not exist"
		end

		local id = ctf_clans.get_clan_id(param)
		if not id then
			return false, "Player not in the clan right now"
		end

		if not ctf_clans.is_clan_exist(id) then
			return false, "Player a member of a clan, but that clan doesn't exist. WTF?"
		end

		local def = ctf_clans.get_clan(id)

		if def.owner == name then
			return false, "The owner cannot leave his clan"
		end

		if not ctf_clans.remove_member(id, param) then
			return true, "Failed"
		end

		return true, "Player left the clan " .. def.clan_name .. " successfully"
	end
})


minetest.register_chatcommand("aclans_remove",{
	description = "Remove the clan",
    privs = {clans = true},
	params = "<clan id>",
	func = function(_, param)
		local id = tonumber(param)
		if not id then
			return false, "No id provided"
		end

		if not ctf_clans.is_clan_exist(id) then
			return false, "The clan doesn't exist"
		end

		local def = ctf_clans.get_clan(id)

		ctf_clans.remove_clan(id)

		return true, "Clan " .. def.clan_name .. " removed successfully"
	end
})

minetest.register_chatcommand("aclans_dump",{
	description = "Print clan's data",
    privs = {clans = true},
	params = "",
	func = function(name, param)
		local target = param
		if param == "" then
			target = name
		end

		if not minetest.get_player_by_name(target) then
			return false, "The player does not exist or offline"
		end

		local id = ctf_clans.get_clan_id(target)
		if id then
			local def = ctf_clans.get_clan(id)
			return true, dump(def) .. "\nID: " .. id
		end
	end
})

minetest.register_chatcommand("adump_clans_ids",{
	description = "Print all ids",
    privs = {clans = true},
	params = "",
	func = function()
		return true, table.concat(ctf_clans.registered_clans, " ")
	end
})

-- For players

minetest.register_chatcommand("clans_left",{
	description = "Left the current clan",
	privs = {},
	params = "",
	func = function(name)
		local id = ctf_clans.get_clan_id(name)
		if not id then
			return false, "You're not in the clan"
		end

		if not ctf_clans.get_clan_member(id, name) then
			return false, "Oh DANG! It seems to be broken. Let the admins know."
		end

		local def = ctf_clans.get_clan(id)
		if def.owner == name then
			ctf_clans.remove_clan(id)
			return false, "The owner cannot leave his clan"
		end

		if not ctf_clans.remove_member(id, name) then
			return true, "Failed for unknown reason. WTF!"
		end

		return true, minetest.colorize("green", "You left the clan " .. def.clan_name .. " successfully")
	end
})

minetest.register_chatcommand("clans_id",{
	description = "Shows the ID of the clan the player is a member of",
	privs = {},
	params = "<Player Name>",
	func = function(_, param)
		if not minetest.get_player_by_name(param) then
			return false, "The player does not exist or offline"
		end
		local id = ctf_clans.get_clan_id(param)
		if not id or id == 0 then
			return false, "The player is not a member of any clan"
		end
		return true, param .. ": " .. id
	end
})

minetest.register_chatcommand("delete_my_clan",{
	description = "Remove the clan",
    privs = {},
	params = "",
	func = function(name)
		local id = ctf_clans.get_clan_id(name)
		if not id then
			return false, "You are not in a clan"
		end

		local def = ctf_clans.get_clan(id)
		if def.owner == name then
			ctf_clans.remove_clan(id)

			local player = minetest.get_player_by_name(name)
			sfinv.set_page(player, sfinv.get_homepage_name(player)) -- refresh the inventory page
			return true, "Your clan has been removed.\nThe current members have been kicked."
		end
		return true, "Only the owner can delete"
	end
})

minetest.register_chatcommand("clans_fix",{
	description = "Fixing something",
    privs = {},
	params = "",
	func = function(name)
		ctf_clans.fix_entry(name)
		return true, "Done"
	end
})
