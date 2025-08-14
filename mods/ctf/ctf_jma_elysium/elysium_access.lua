local storage = core.get_mod_storage()
local ACCESS_KEY = "access_"
local ACCESS_DURATION = 1 * 24 * 60 * 60
local INACTIVITY_DURATION = 3 * 24 * 60 * 60
local cache = {}
local invites = {}
local quick_help = "Welcome to JMA Elysium! %s: %s\n" ..
	"To leave, type /leave or simply disconnect from the server.\n" ..
	"Want to invite someone? Use /einvite <player>.\n" ..
	"To talk in global chat, use /g <message>.\n" ..
	"Use /espawn to return to Elysium's spawn point.\n" ..
	"Note: JMA Elysium is currently under development and bugs may occur."

local REJOIN_COOLDOWN = ctf_core.init_cooldowns()
local MAX_ELYSIUM_JOINS = 4
local join_count = {}

local TASKS = {
	{
		key = "flag_captures",
		label = "Capture the flag",
		goal = 1,
	},
	{
		key = "hp_healed",
		label = "Heal 100 HP",
		goal = 100,
	},
}

local function get_mode_rankings(mode_name, player_name)
	local mode = ctf_modebase.modes[mode_name]
	return mode and mode.rankings:get(player_name) or {}
end

local function collect(player_name)
	local total = {}

	for mode_name in pairs(ctf_modebase.modes) do
		for k, v in pairs(get_mode_rankings(mode_name, player_name)) do
			total[k] = (total[k] or 0) + v
		end
	end

	return {total = total}
end

local function get_cached_rankings(name)
	local now = os.time()
	if not cache[name] or cache[name].last_update < now - 3 then
		cache[name] = {
			last_update = now,
			total = collect(name).total
		}
	end
	return cache[name].total
end

local function get_checkpoint_key(stat_key, player_name)
	return string.format("checkpoint_%s_%s", stat_key, player_name)
end

local function reset_checkpoints(name)
	local stats = collect(name).total
	for _, quest in ipairs(TASKS) do
		storage:set_int(get_checkpoint_key(quest.key, name), stats[quest.key] or 0)
	end
end

local function has_access(name)
	local t = storage:get_float(ACCESS_KEY .. name)
	if t > os.time() then
		return true, t
	end
	return false
end

local function get_quest_progress(name)
	local stats = get_cached_rankings(name)
	local msg = {}
	local all_done = true

	for _, quest in ipairs(TASKS) do
		local stat = stats[quest.key] or 0
		local checkpoint_key = get_checkpoint_key(quest.key, name)

		if not storage:contains(checkpoint_key) then
			storage:set_int(checkpoint_key, stat)
		end

		local checkpoint = storage:get_int(checkpoint_key)
		-- Ensure that checkpoint is not greater than status
		if checkpoint > stat then
			checkpoint = stat
			storage:set_int(checkpoint_key, stat)
		end

		local progress = stat - checkpoint
		local done = progress >= quest.goal

		if done then
			table.insert(msg, core.colorize("#00ff00", string.format("[Done] %s", quest.label)))
		else
			local left = math.max(quest.goal - progress, 0)
			table.insert(msg, core.colorize("#ffcc00", string.format("[Required] %s: %d left", quest.label, left)))
			all_done = false
		end
	end

	if all_done then
		table.insert(msg, core.colorize("#00ff00", "All tasks completed"))
	end

	return all_done, table.concat(msg, "\n")
end

core.register_on_joinplayer(function(player, last_login)
	local name = player:get_player_name()
	local dropped = false

	local t = storage:get_float(ACCESS_KEY .. name)
	if t < os.time() and t > 0  then
		storage:set_float(ACCESS_KEY .. name, 0)
		reset_checkpoints(name)
		dropped = true
		core.chat_send_player(name, "Your Elysium ticket has expired.")
	end

	if not dropped then
		local last_leave = playtime.get_last_leave(name)
		if os.time() - last_leave > INACTIVITY_DURATION then
			storage:set_float(ACCESS_KEY .. name, 0)
			reset_checkpoints(name)
			core.log("action", string.format("Quest progress for %s has been reset due to inactivity.", name))
		end
	end
end)

core.register_on_leaveplayer(function(player)
	local name = player:get_player_name()
	cache[name] = nil
	invites[name] = nil
end)

ctf_api.register_on_match_end(function()
	for _, player in ipairs(core.get_connected_players()) do
		local name = player:get_player_name()
		local now = os.time()
		local access = has_access(name)
		local is_done, _ = get_quest_progress(name)

		if is_done and not access then
			storage:set_float(ACCESS_KEY .. name, now + ACCESS_DURATION)
			core.chat_send_player(name, core.colorize("#00ff00", "[Elysium] Quest completed! You have earned a " ..
				"ticket to Elysium for " .. playtime.seconds_to_clock(ACCESS_DURATION)))
		end
	end
end)

function ctf_jma_elysium.grant_access(name, duration_seconds)
	local now = os.time()
	local current_access_time = storage:get_float(ACCESS_KEY .. name)
	local new_access_time

	if current_access_time > now then
		new_access_time = current_access_time + duration_seconds
	else
		new_access_time = now + duration_seconds
	end

	storage:set_float(ACCESS_KEY .. name, new_access_time)

	local player = core.get_player_by_name(name)
	if player then
		core.chat_send_player(name,
			core.colorize("#00ff00", "[Elysium] You have been granted access for " ..
			playtime.seconds_to_clock(duration_seconds) .. "!"))
	end
end

ctf_api.register_on_match_end(function()
	join_count = {}
end)

local function join(player, name, cb)
	ctf_jma_elysium.join(player, function()
		join_count[name] = (join_count[name] or 0) + 1
		REJOIN_COOLDOWN:set(player, 60)
		cb()
	end)
end

core.register_chatcommand("elysium", {
	privs = {interact = true},
	description = "Join Elysium (if you meet the requirements or were invited)",
	func = function(name)
		local player = core.get_player_by_name(name)

		local can_join, reason = ctf_jma_elysium.can_player_join_elysium(name)
		if not can_join then
			return false, reason
		end

		if join_count[name] and join_count[name] >= MAX_ELYSIUM_JOINS then
			return false, "You cannot rejoin Elysium - maximum join attempts reached for the current match."
		end

		if REJOIN_COOLDOWN:get(player) then
			return false, "You're rejoining too quickly - please wait 1 minute before trying again."
		end

		local now = os.time()
		local has_acc, ticket_time = has_access(name)
		if has_acc then
			join(player, name, function()
				core.chat_send_player(name,  quick_help:format("Time left", playtime.seconds_to_clock(ticket_time - now)))
			end)

			return true
		end

		-- Temporary ticket
		if invites[name] then
			join(player, name, function()
				core.chat_send_player(name,  quick_help:format("[Invite]", "Ends after leaving Elysium or disconnecting"))
				invites[name] = nil
			end)

			return true
		end

		local is_done, msg = get_quest_progress(name)
		if not is_done then
			return false, "Complete the quest to get a ticket to access Elysium.\n" .. msg
		end

		reset_checkpoints(name)
		storage:set_float(ACCESS_KEY .. name, now + ACCESS_DURATION)
		join(player, name, function()
			core.chat_send_player(name, string.format(quick_help, "Time left", playtime.seconds_to_clock(ACCESS_DURATION)))
		end)

		return true
	end
})

core.register_chatcommand("leave", {
	privs = {interact = true},
	description = "Leave Elysium",
	func = function(name)
		local player = core.get_player_by_name(name)
		if not player then
			return false, "You are offline."
		end

		if not ctf_modebase.current_mode then
			return false, "The game isn't running."
		end

		if not ctf_jma_elysium.get_player(name) then
			return false, "You are not in Elysium."
		end

		if not ctf_modebase.in_game then
			return false, "Please wait until the game starts to leave Elysium or disconnect from the server."
		end

		if ctf_jma_elysium.leave(player) then
			return true, "You have left Elysium."
		end

		return false, "Something went wrong. Please contact Nanowolf4 (n4w@tutanota.com)"
	end
})

core.register_chatcommand("eprogress", {
	privs = {interact = true},
	description = "Show your Elysium quest progress",
	func = function(name)
		local status, t = has_access(name)
		if status then
			local seconds_left = t - os.time()
			return true, string.format(
				"You have a ticket to Elysium!\nUse /elysium to enter.\nTime left: %s",
				playtime.seconds_to_clock(seconds_left)
			)
		end

		local qstatus, msg = get_quest_progress(name)
		if qstatus then
			return true, msg .. "\nNow you can use /elysium to enter!"
		else
			return true, "Complete the quest to get a ticket to access Elysium.\n" .. msg
		end
	end
})

core.register_chatcommand("einvite", {
	privs = {interact = true},
	params = "<player>",
	description = "Invite one player to Elysium (session-only)",
	func = function(name, param)
		local target = param:trim()
		if target == "" or target == name then
			return false, "Invalid player name."
		end

		if not core.get_player_by_name(target) then
			return false, "Player must be online"
		end

		local invited_count = 0
		for _, inviter in pairs(invites) do
			if inviter == name then
				invited_count = invited_count + 1
			end
		end
		if invited_count >= 1 then
			return false, "You have already invited someone."
		end

		if invites[target] then
			return false, "This player has already been invited."
		end

		local access = has_access(name)
		if not access or invites[name] then
			return false, "You cannot invite players (no access or you were invited)."
		end

		for invited, inviter in pairs(invites) do
			if inviter == name then
				return false, "You have already invited someone."
			end
		end

		invites[target] = name
		core.chat_send_player(target, core.colorize("#00ff00",
			"You have received a one-time Elysium invite from " .. name .. "!\n" ..
			"Use /elysium to enter. This ticket is valid for a single entry only."
		))
		return true, "You have invited " .. target .. " to Elysium."
	end
})

core.register_chatcommand("el_ajoin", {
	privs = {ctf_admin = true},
	description = "Join Elysium ignoring all restrictions (admin command)",
	func = function(name)
		local player = core.get_player_by_name(name)
		if not player then
			return false, "You are offline."
		end
		if ctf_jma_elysium.players[name] then
			return false, "You're already in Elysium. Use /leave to exit."
		end
		ctf_jma_elysium.join(player)
		return true, "You have joined Elysium."
	end
})

core.register_chatcommand("el_lock", {
	privs = {ctf_admin = true},
	params = "on|off",
	description = "Lock or unlock Elysium",
	func = function(name, param)
		param = param and param:lower()
		if param == "on" then
			ctf_jma_elysium.elysium_locked = true
			return true, "Elysium is now locked for all players."
		elseif param == "off" then
			ctf_jma_elysium.elysium_locked = false
			return true, "Elysium is now unlocked."
		else
			return false, "Usage: /el_lock on|off"
		end
	end
})

core.register_chatcommand("el_give_access", {
	privs = {ctf_admin = true},
	params = "<player> <minutes>",
	description = "Give Elysium access to a player for a specified number of minutes",
	func = function(name, param)
		local args = param:split(" ")
		local target = args[1]
		local minutes = tonumber(args[2])
		if not target or not minutes then
			return false, "Usage: /el_give_access <player> <minutes>"
		end
		if minutes < 1 then
			return false, "Invalid minutes value"
		end

        local seconds = minutes * 60
		ctf_jma_elysium.grant_access(target, seconds)
		return true, "Access granted to " .. target .. " for " .. playtime.seconds_to_clock(seconds)
	end
})

core.register_chatcommand("el_kick", {
	privs = {ctf_admin = true},
	params = "<player>",
	description = "Kick a player from Elysium",
	func = function(name, target)
		if not target or target == "" then
			return false, "Usage: /el_kick <player>"
		end

		if not ctf_jma_elysium.get_player(target) then
			return false, "This player is not in Elysium"
		end

		local player = core.get_player_by_name(target)
		if not player then
			return false, "Player is not online but is in Elysium... how?"
		end

		ctf_jma_elysium.leave(player)
		core.chat_send_player(target, "[Elysium] You have been kicked by an admin. Bye!")
		return true, "Player " .. target .. " has been kicked from Elysium."
	end
})
