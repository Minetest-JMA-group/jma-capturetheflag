ctf_chat = {}
local colorize = minetest.colorize

minetest.override_chatcommand("msg", {
	func = function(name, param)
		local sendto, message = param:match("^(%S+)%s(.+)$")
		if not sendto then
			return false, "Invalid usage, see /help msg."
		end
		if not minetest.get_player_by_name(sendto) then
			return false, "The player " .. sendto .. " is not online."
		end

		-- Run the message through filter if it exists
		if filter and not filter.check_message(message) then
			filter.on_violation(name, message)
			return false, "Watch your language!"
		end

		-- Message color
		local color = minetest.settings:get("ctf_chat.message_color") or "#E043FF"
		local pteam = ctf_teams.get(name)
		local tcolor = pteam and ctf_teams.team[pteam].color or "#FFF"

		-- Colorize the recepient-side message and send it to the recepient
		local str =  colorize(color, "PM from ")
		str = str .. colorize(tcolor, name)
		str = str .. colorize(color, ": " .. message)
		minetest.chat_send_player(sendto, str)

		-- Make the sender-side message
		str = "Message sent to " .. sendto .. ": " .. message

		minetest.log("action", string.format("[CHAT] PM from %s to %s: %s", name, sendto, message))

		-- Send the sender-side message
		return true, str
	end
})

function ctf_chat.send_me(name, param)
end

minetest.override_chatcommand("me", {
	func = function(name, param)
		minetest.log("action", string.format("[CHAT] ME from %s: %s", name, param))

		ctf_chat.send_me(name, param)

		local pteam = ctf_teams.get(name)
		if pteam then
			local tcolor = ctf_teams.team[pteam].color
			name = colorize(tcolor, "* " .. name)
		else
			name = "* ".. name
		end

		minetest.chat_send_all(name .. " " .. param)
	end
})

minetest.register_chatcommand("t", {
	params = "msg",
	description = "Send a message on the team channel",
	privs = { interact = true, shout = true },
	func = function(name, param)
		if param == "" then
			return false, "-!- Empty team message, see /help t"
		end

		local tname = ctf_teams.get(name)
		if tname then
			minetest.log("action", string.format("[CHAT] team message from %s (team %s): %s", name, tname, param))

			local tcolor = ctf_teams.team[tname].color
			for username in pairs(ctf_teams.online_players[tname].players) do
				minetest.chat_send_player(username,
						colorize(tcolor, "<" .. name .. "> ** " .. param .. " **"))
			end
		else
			minetest.chat_send_player(name,
					"You're not in a team, so you have no team to talk to.")
		end
	end
})

-- Formatting chat messages
local oldFunction = minetest.format_chat_message or function(name, message) return message end
function minetest.format_chat_message(name, message)
	local pteam_color = "white"
	local pteam = ctf_teams.get(name)
	if pteam then
		pteam_color = ctf_teams.team[pteam].color
	end

	local msg = string.format("<%s>: %s", colorize(pteam_color, name), message)

	local rank = ranks.get_player_prefix(name)

	local pro = false
	local current_mode = ctf_modebase:get_current_mode()
	if current_mode and current_mode.player_is_pro and current_mode.player_is_pro(name) == true then
		pro = true
	end

	local pro_prefix = "[PRO]"
	if rank and pro then
		msg = string.format("%s %s %s", colorize(pteam_color, pro_prefix), colorize(rank.color, rank.prefix), msg)
	elseif pro and not rank then
		msg = string.format("%s %s", colorize(pteam_color, pro_prefix), msg)
	elseif not pro and rank then
		msg = string.format("%s %s", colorize(rank.color, rank.prefix), msg)
	end
	return oldFunction(name, msg)
end
