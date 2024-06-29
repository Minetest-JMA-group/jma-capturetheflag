-- * Copyright (c) 2024 Nanowolf4  (E-Mail: n4w@tutanota.com, XMPP/Jabber: n4w@nixnet.serivces)
-- * SPDX-License-Identifier: GPL-3.0-or-later

local storage = minetest.get_mod_storage()

chat_lib.relay_allowed_chat_commands = {}
if storage:contains("whitelist") then
	chat_lib.relay_allowed_chat_commands = minetest.deserialize(storage:get_string("whitelist"))
else
	chat_lib.relay_allowed_chat_commands = dofile(minetest.get_modpath("chat_lib") .. "/relay_chat_commands.lua")
end

function chat_lib.chatcommand_check_privs(name, command)
	local def = minetest.registered_chatcommands[command]
	local required_privs = def.privs
	local player_privs = minetest.get_player_privs(name)
	if type(required_privs) == "string" then
		required_privs = {[required_privs] = true}
	end
	for priv, value in pairs(required_privs) do
		if player_privs[priv] ~= value then
			return false
		end
	end
	return true
end

local send_player_callback = {}
chat_lib.register_on_chat_send_player(function(name, message)
	if send_player_callback[name] then
		return send_player_callback[name](name, message)
	end
end)

function chat_lib.execute_chatcommand(name, command, param, callback)
	if callback then
		send_player_callback[name] = callback
	end

	local success, ret_val = minetest.registered_chatcommands[command].func(name, param or "")
	send_player_callback[name] = nil
	return success, ret_val
end

function chat_lib.relay_is_chatcommand_allowed(command)
	return chat_lib.relay_allowed_chat_commands[command]
end

minetest.register_chatcommand("relay_commands", {
	description = "Execute relay management command",
	params = "<command> <command_args>",
	privs = {dev=true},
	func = function(name, param)
		local iter = param:gmatch("%S+")
		local command = iter()
		local allowed_commands = chat_lib.relay_allowed_chat_commands

		if command == "help" then
			local help = "List of possible commands:\n" ..
				"reload: Overwrite command whitelist with the content of the file on the server\n" ..
				"dump: Print the content of the allowed_commands\n" ..
				"add <command_name>: Add command to the whitelist\n" ..
				"rm <command_name>: Remove command from the whitelist"
			return true, help

		elseif command == "add" then
			local cmdname = iter()
			if not cmdname or cmdname == "" then
				return false, "You have to enter valid command name to "..command
			end
			if allowed_commands[cmdname] then
				return false, "Command "..cmdname.." is already in the whitelist"
			end
			allowed_commands[cmdname] = true
			storage:set_string("whitelist", minetest.serialize(allowed_commands))
			return true, "Added "..cmdname.." to the whitelist"

		elseif command == "rm" then
			local cmdname = iter()
			if not cmdname or cmdname == "" then
				return false, "You have to enter valid command name to "..command
			end
			if not allowed_commands[cmdname] then
				return false, "Command "..cmdname.." hasn't existed in the whitelist"
			end
			allowed_commands[cmdname] = nil
			storage:set_string("whitelist", minetest.serialize(allowed_commands))
			return true, "Removed "..cmdname.." from the whitelist"

		elseif command == "reload" then
			allowed_commands = dofile(minetest.get_modpath("chat_lib") .. "/relay_chat_commands.lua")
			storage:set_string("whitelist", minetest.serialize(allowed_commands))
			return true, "Whitelist reloaded"

		elseif command == "dump" then
			minetest.chat_send_player(name, dump(allowed_commands))
			return true
		end

		return false, "Invalid command; Run /relay_commands help for available commands"
	end,
})