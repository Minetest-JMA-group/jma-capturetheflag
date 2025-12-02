--- @alias FlagCarrier { name: PlayerName, team: Team }

-- this is table of streaks.
-- mega streak means 4 or 5 attempt in less than 10 minutes
ctf_modebase.flag_attempt_streaks = {
	[3] = "COMBO",
	[4] = "RAMPAGE",
	[5] = "FRENZY",
	[7] = "UNSTOPPABLE",
	[8] = "RELENTLESS",
	[10] = "FLAGMASTER",
	[12] = "FLAG SEEKER",
	[14] = "FLAG HUNTER",
	[15] = "CAPTAIN FLAG",
	[18] = "SUPERCALIFLAGALISTIC",
	[20] = "FLAG MAGNET",
	[25] = "KEYBOARD NINJA",
	[30] = "FLAG-A-HOLIC",
	[35] = "MEGA BRAIN",
	[40] = "FLAG WHISPERER",
	[45] = "GALAXY BRAIN",
	[50] = "FLAG VIRTUOSO",
	[60] = "FLAG CONQUISTADOR",
	[70] = "CAPTAIN OBVIOUS",
	[80] = "FLAG COLLECTOR EXTREME",
	[90] = "FLAG DEITY",
	[100] = "GOD MODE",
	[125] = "BEYOND MORTAL",
	[150] = "ALGORITHM ANOMALY",
	[200] = "QUANTUM HACKER",
	[201] = "GALACTIC NUB",
	[210] = "DONE THIS GAME! OFFICIALLY A HACKER!",
}

local MAX_STREAK = 210

local function get_streak_color(attempts)
	-- Light green to Dark green (1-15)
	if attempts <= 5 then
		return "#00FF00" -- Light green
	elseif attempts <= 10 then
		return "#00DD00" -- Medium green
	elseif attempts <= 15 then
		return "#009900" -- Dark green
	-- Yellow to Orange (16-50)
	elseif attempts <= 25 then
		return "#FFFF00" -- Yellow
	elseif attempts <= 35 then
		return "#FFAA00" -- Light orange
	elseif attempts <= 50 then
		return "#FF7700" -- Dark orange
	-- Bright orange to Red (51-100)
	elseif attempts <= 70 then
		return "#FF5500" -- Bright orange
	elseif attempts <= 85 then
		return "#FF2200" -- Orange-red
	elseif attempts <= 100 then
		return "#FF0000" -- Pure red
	-- Light red to Purple (101-210)
	elseif attempts <= 150 then
		return "#FF0066" -- Light red
	elseif attempts <= 200 then
		return "#FF0099" -- Pink-red
	else
		return "#FF00FF" -- Purple
	end
end

local function drop_flags(player, pteam)
	local pname = player:get_player_name()
	local flagteams = ctf_modebase.taken_flags[pname]
	if not flagteams then
		return
	end

	for _, flagteam in ipairs(flagteams) do
		ctf_modebase.flag_taken[flagteam] = nil

		local fpos = vector.offset(ctf_map.current_map.teams[flagteam].flag_pos, 0, 1, 0)

		core.load_area(fpos)
		local node = core.get_node(fpos)

		if node.name == "ctf_modebase:flag_captured_top" then
			node.name = "ctf_modebase:flag_top_" .. flagteam
			core.set_node(fpos, node)
		else
			core.log(
				"error",
				string.format(
					"[ctf_flags] Unable to return flag node=%s, pos=%s",
					node.name,
					vector.to_string(fpos)
				)
			)
		end
	end

	player_api.set_texture(player, 2, "blank.png")

	ctf_modebase.taken_flags[pname] = nil

	ctf_modebase.skip_vote.on_flag_drop(#flagteams)
	ctf_modebase:get_current_mode().on_flag_drop(player, flagteams, pteam)
end

function ctf_modebase.drop_flags(player)
	drop_flags(player, ctf_teams.get(player))
end

function ctf_modebase.flag_on_punch(puncher, nodepos, node)
	local pname = puncher:get_player_name()
	local pteam = ctf_teams.get(pname)

	if not pteam then
		hud_events.new(puncher, {
			quick = true,
			text = "You're not in a team, you can't take that flag!",
			color = "warning",
		})
		return
	end

	local top = node.name:find("top_")
	if not top then
		return
	end
	local target_team = node.name:sub(top + 4)

	if pteam ~= target_team then
		if ctf_modebase.flag_captured[pteam] then
			hud_events.new(puncher, {
				quick = true,
				text = "You can't take that flag. Your team's flag was captured!",
				color = "warning",
			})
			return
		end

		local result = ctf_modebase:get_current_mode().can_take_flag(puncher, target_team)
		if result then
			hud_events.new(puncher, {
				quick = true,
				text = result,
				color = "warning",
			})
			return
		end

		if not ctf_modebase.match_started then
			return
		end

		if not ctf_modebase.taken_flags[pname] then
			ctf_modebase.taken_flags[pname] = {}
		end
		table.insert(ctf_modebase.taken_flags[pname], target_team)
		ctf_modebase.flag_taken[target_team] = { name = pname, team = pteam }

		if ctf_modebase.flag_attempt_history[pname] == nil then
			ctf_modebase.flag_attempt_history[pname] = {}
		end
		table.insert(ctf_modebase.flag_attempt_history[pname], os.time())

		local number_of_attempts = 0
		local total_time = 0 -- should be less than 60*10 = 10 minutes
		local prev_time = nil
		local new = nil
		for i = #ctf_modebase.flag_attempt_history[pname], 1, -1 do
			local time = ctf_modebase.flag_attempt_history[i]

			if prev_time then
				total_time = prev_time - time
			else
				prev_time = time
			end

			if total_time >= 60 * 10 then
				if not new then
					new = table.copy(ctf_modebase.flag_attempt_history[pname])
				end

				table.remove(new, 1)
			else
				number_of_attempts = number_of_attempts + 1
			end
		end

		if new then
			ctf_modebase.flag_attempt_history[pname] = new
		end

		if number_of_attempts > MAX_STREAK then
			number_of_attempts = MAX_STREAK
		end

		local streak = ctf_modebase.flag_attempt_streaks[number_of_attempts]
		if streak then
			ctf_modebase.player_on_flag_attempt_streak[pname] = number_of_attempts

			local color = get_streak_color(number_of_attempts)
			core.chat_send_all(
				string.format(
					"%s is on a %s attempt streak with %d attempts!",
					core.colorize(ctf_teams.team[pteam].color, pname),
					core.colorize(color, streak),
					number_of_attempts
				)
			)
		end

		player_api.set_texture(
			puncher,
			2,
			"default_wood.png^([combine:16x16:4,0=wool_white.png^[colorize:"
				.. ctf_teams.team[target_team].color
				.. ":200)"
		)

		ctf_modebase.skip_vote.on_flag_take()
		ctf_modebase:get_current_mode().on_flag_take(puncher, target_team)

		RunCallbacks(ctf_api.registered_on_flag_take, puncher, target_team)

		core.set_node(
			nodepos,
			{ name = "ctf_modebase:flag_captured_top", param2 = node.param2 }
		)
	else
		local flagteams = ctf_modebase.taken_flags[pname]
		if not ctf_modebase.taken_flags[pname] then
			hud_events.new(puncher, {
				quick = true,
				text = "That's your flag!",
				color = "warning",
			})
		else
			ctf_modebase.taken_flags[pname] = nil

			for _, flagteam in ipairs(flagteams) do
				ctf_modebase.flag_taken[flagteam] = nil
				ctf_modebase.flag_captured[flagteam] = true
			end

			player_api.set_texture(puncher, 2, "blank.png")

			ctf_modebase.on_flag_capture(puncher, flagteams)

			ctf_modebase.skip_vote.on_flag_capture(#flagteams)
			ctf_modebase:get_current_mode().on_flag_capture(puncher, flagteams)
		end
	end
end

ctf_api.register_on_match_end(function()
	for pname in pairs(ctf_modebase.taken_flags) do
		player_api.set_texture(core.get_player_by_name(pname), 2, "blank.png")
	end

	ctf_modebase.taken_flags = {}
	ctf_modebase.flag_taken = {}
	ctf_modebase.flag_captured = {}
	ctf_modebase.flag_attempt_history = {}
	ctf_modebase.player_on_flag_attempt_streak = {}
end)

ctf_teams.register_on_allocplayer(function(player, new_team, old_team)
	if ctf_modebase.taken_flags[player:get_player_name()] then
		drop_flags(player, old_team)
	else
		ctf_modebase.flag_huds.update_player(player)
	end
end)

core.register_on_dieplayer(function(player)
	ctf_modebase.drop_flags(player)
end)

core.register_on_leaveplayer(function(player)
	ctf_modebase.drop_flags(player)
end)
