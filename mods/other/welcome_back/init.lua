-- SPDX-License-Identifier: LGPL-2.1-only
-- Copyright (c) 2023 Marko Petrović

local msg_price = 10
local msg_num_limit = 1
local msg_interval_limit = 3600

local storage = core.get_mod_storage()

local function get_gamemode(param)
	local opt_param, mode_param = ctf_modebase.match_mode(param)

	if mode_param then
		local mode = ctf_modebase.modes[mode_param]
		if mode_param == "all" then
			return "all", nil, opt_param
		elseif not mode then
			return false, "No such game mode: " .. mode_param
		end

		return mode_param, mode, opt_param
	else
		local current_mode = ctf_modebase:get_current_mode()
		if not current_mode then
			return false, "The game isn't running"
		end

		return ctf_modebase.current_mode, current_mode, opt_param
	end
end

-- ********** Time limit functions **********

local function clear_old_times(timestamp_table, giver_name)
	local curtime = os.time()
	local timestamp_updated_table = {}
	for _, time in ipairs(timestamp_table) do
		if (curtime - time) < msg_interval_limit then
			table.insert(timestamp_updated_table, time)
		end
	end
	return timestamp_updated_table
end

local function limit_reached(giver_name)
	local table_key = "timestamp_table:" .. giver_name
	local timestamp_table = core.deserialize(storage:get_string(table_key)) or {}

	timestamp_table = clear_old_times(timestamp_table, giver_name)
	storage:set_string(table_key, core.serialize(timestamp_table))
	return #timestamp_table > msg_num_limit
end

local function record_timestamp(giver_name)
	local table_key = "timestamp_table:" .. giver_name
	local timestamp_table = core.deserialize(storage:get_string(table_key)) or {}
	table.insert(timestamp_table, os.time())
	storage:set_string(table_key, core.serialize(timestamp_table))
end

-- ********** Gift managing helpers **********

local function load_gift(mode_name, receiver_name)
	return core.deserialize(storage:get_string(mode_name .. ":" .. receiver_name))
		or {}
end

local function save_gift(score, giver_name, mode_name, receiver_name)
	local gift_table = load_gift(mode_name, receiver_name)
	gift_table[giver_name] = score + (gift_table[giver_name] or 0)
	storage:set_string(mode_name .. ":" .. receiver_name, core.serialize(gift_table))
end

local function dispatch_gifts(receiver_name)
	for mode_name, mode_data in pairs(ctf_modebase.modes) do
		local gift_table = load_gift(mode_name, receiver_name)
		for giver_name, score in pairs(gift_table) do
			local old_receiver_ranks = mode_data.rankings:get(receiver_name)
			local old_receiver_score = old_receiver_ranks.score or 0
			mode_data.rankings:set(receiver_name, { score = old_receiver_score + score })
			core.chat_send_player(
				receiver_name,
				core.colorize("#01D800", giver_name)
					.. string.format(
						" has welcomed you with the %i score gift in mode %s!",
						score,
						mode_name
					)
			)
		end
		storage:set_string(mode_name .. ":" .. receiver_name, "")
	end
end

-- ********** REGISTRATIONS **********

core.register_chatcommand("wb", {
	description = string.format(
		"Send a welcoming message to the player with a gift of %i score",
		msg_price
	),
	params = "[mode:technical modename] <playername>",
	func = function(giver_name, param)
		local mode_name, mode_data, receiver_name = get_gamemode(param)
		if not mode_name then
			return false, mode_data
		end
		if not receiver_name then
			return false, "You have to provide player name!"
		end

		if
			core.global_exists("block_msgs")
			and block_msgs.is_chat_blocked(giver_name, receiver_name)
		then
			return false,
				receiver_name
					.. " has you on their block list. You cannot interact with them."
		end

		local old_receiver_ranks = mode_data.rankings:get(receiver_name)
		if not old_receiver_ranks then
			return false, string.format("Player '%s' has no rankings!", receiver_name)
		end

		local old_giver_ranks = mode_data.rankings:get(giver_name)
		if not old_giver_ranks then
			return false, string.format("Player '%s' has no rankings!", giver_name)
		end

		if old_giver_ranks.score == nil or old_giver_ranks.score < msg_price then
			return false,
				string.format(
					"You don't have enough score to give! You need at least %i score.",
					msg_price
				)
		end

		if limit_reached(giver_name) then
			return false,
				string.format(
					"You have to wait; you can only send %i messages every %i minutes.",
					msg_num_limit,
					msg_interval_limit / 60
				)
		end

		-- All checks passed. Send the Welcome message
		record_timestamp(giver_name)
		mode_data.rankings:set(giver_name, { score = old_giver_ranks.score - msg_price })
		save_gift(msg_price, giver_name, mode_name, receiver_name)

		if core.get_player_by_name(receiver_name) then
			dispatch_gifts(receiver_name)
		end

		core.log(
			"action",
			string.format(
				"Player %s welcomed player %s with %i more score in mode %s",
				giver_name,
				receiver_name,
				msg_price,
				mode_name
			)
		)
		return true,
			string.format(
				"Gifted %i score to player '%s' via welcome message",
				msg_price,
				receiver_name
			)
	end,
})

core.register_on_joinplayer(function(player)
	local receiver_name = player:get_player_name()
	dispatch_gifts(receiver_name)
end)
