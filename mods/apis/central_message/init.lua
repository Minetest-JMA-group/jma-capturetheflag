-- Central Message API
-- This mod originally developed by Viper (Viperian Realms server)

cmsg = {}
cmsg.hudids = {}
cmsg.messages = {}
cmsg.next_msgids = {}

local function update_display(player, pname)
	local messages = {}
	local count = #cmsg.messages[pname]
	local start = count-10 > 0 and count-10 or 1
	for i=start, count do
		table.insert(messages, cmsg.messages[pname][i].text)
	end
	local concat = table.concat(messages, "\n")
	player:hud_change(cmsg.hudids[pname], "text", concat)
end

cmsg.push_message_player = function(player, text)
	local pname = player:get_player_name()
	if not player or not pname or pname == "" or player.is_fake_player then return end
	if pname and cmsg.hudids[pname] == nil or (player:hud_get(cmsg.hudids[pname]) and player:hud_get(cmsg.hudids[pname]).number ~= 16777214) then
		cmsg.hudids[pname] = player:hud_add({
			type = "text",
			text = text,
			number = 0xFFFFFE,
			position = {x=0, y=0.5},
			offset = {x=10,y=0},
			alignment = {x=1,y=0},
			scale = {x=-50,y=-25},
		})
		cmsg.messages[pname] = {}
		cmsg.next_msgids[pname] = 0
		table.insert(cmsg.messages[pname], {text=text, msgid=cmsg.next_msgids[pname]})
	else
		cmsg.next_msgids[pname] = cmsg.next_msgids[pname] + 1
		table.insert(cmsg.messages[pname], {text=text, msgid=cmsg.next_msgids[pname]})
		update_display(player, pname)
	end

	core.after(5, function(param)
		if not param.player then
			return
		end
		local pname = param.player:get_player_name()
		if not pname then
			return
		end
		if not cmsg.messages[pname] then
			return
		end
		for i=1, #cmsg.messages[pname] do
			if param.msgid == cmsg.messages[pname][i].msgid then
				table.remove(cmsg.messages[pname], i)
				break
			end
		end
		update_display(player, pname)
	end, {player=player, msgid=cmsg.next_msgids[pname]})
end

cmsg.push_message_all = function(text)
	local players = core.get_connected_players()
	for i=1,#players do
		cmsg.push_message_player(players[i], text)
	end
end

core.register_on_leaveplayer(function(player)
	cmsg.hudids[player:get_player_name()] = nil
end)

core.register_chatcommand("cmsg", {
	params = "<player> <message>",
	description = "Send a message to all players or a specific player",
	privs = {server=true},
	func = function(name, param)
		local target, message = param:match("^(%S+)%s+(.+)$")
		if not message then
			return false, "Usage: /cmsg <player> <message>"
		end

		if target:match("^!") then
			cmsg.push_message_all(message)
			return true, "Message sent to all players."
		else
			local player = core.get_player_by_name(target)
			if player then
				cmsg.push_message_player(player, message)
				return true, "Message sent to " .. target .. "."
			else
				return false, "Player " .. target .. " not found."
			end
		end
	end
})
