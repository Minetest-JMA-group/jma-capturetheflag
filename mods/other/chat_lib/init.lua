chat_lib = {
	registered_on_chat_send_all = {},
	registered_on_chat_send_player = {}
}

function chat_lib.register_on_chat_send_all(func)
	table.insert(chat_lib.registered_on_chat_send_all, func)
end

function chat_lib.register_on_chat_send_player(func)
	table.insert(chat_lib.registered_on_chat_send_player, func)
end

chat_lib.chat_send_all = minetest.chat_send_all
chat_lib.chat_send_player = minetest.chat_send_player

function minetest.chat_send_all(message)
	for _, func in ipairs(chat_lib.registered_on_chat_send_all) do
		if func(message) == true then
			-- Message is handled, not be sent to all players
			return
		end
	end

	chat_lib.chat_send_all(message)
end

function minetest.chat_send_player(name, message)
	for _, func in ipairs(chat_lib.registered_on_chat_send_player) do
		if func(name, message) == true then
			-- Message is handled, not be sent to player
			return
		end
	end

	chat_lib.chat_send_player(name, message)
end


dofile(minetest.get_modpath("chat_lib") .. "/chat_commands_utils.lua")