ctf_chat = {}
local callbacks = {}
local prefix_callbacks = {}
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

minetest.override_chatcommand("me", {
	func = function(name, param)
		minetest.log("action", string.format("[CHAT] ME from %s: %s", name, param))

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
				if not block_msgs or not block_msgs.is_chat_blocked(name, username) then
					minetest.chat_send_player(username,
							colorize(tcolor, "[TEAM] <" .. name .. "> ** " .. param .. " **"))
				end
			end
		else
			minetest.chat_send_player(name,
					"You're not in a team, so you have no team to talk to.")
		end
	end
})

-- Register a function to format the chat message
function ctf_chat.register_on_chat_message_format(func)
	table.insert(callbacks, func)
end

-- Register a prefix with a priority (lower number = higher priority)
function ctf_chat.register_prefix(priority, func)
	table.insert(prefix_callbacks, {priority = priority, func = func})
	table.sort(prefix_callbacks, function(a, b)
		return a.priority < b.priority
	end)
end

local function format_prefixes(name, pteam_color)
	local prefixes = {}

	for _, cb in ipairs(prefix_callbacks) do
		local prefix = cb.func(name, pteam_color)
		if prefix and prefix ~= "" then
			table.insert(prefixes, prefix)
		end
	end

	return table.concat(prefixes, " ")
end

-- Main chat message formatting function
function minetest.format_chat_message(name, message)
	if filter_caps then
		message = filter_caps.parse(name, message)
	end

	local pteam_color = "white"
	local pteam = ctf_teams.get(name)
	if pteam then
		pteam_color = ctf_teams.team[pteam].color
	end

	local colorized_name = minetest.colorize(pteam_color, name)
	local prefixes = format_prefixes(name, pteam_color)
	local formatted_msg = joinStrings(prefixes, "<" .. colorized_name .. ">:", " ", message)

	if not formatted_msg or #formatted_msg == 0 then
		minetest.log("error", "[ctf_chat]: Chat message formatting failed! Player: " .. name .. " Raw msg: " .. message)
		return string.format("<%s>: %s", name or "unknown", message or "")
	end

	local components = {
		name = name,
		message = message,
		prefixes = prefixes,
	}

	RunCallbacks(callbacks, formatted_msg, components)

	return formatted_msg
end