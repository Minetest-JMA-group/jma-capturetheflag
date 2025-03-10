-- this is table of streaks.
-- mega streak means 4 or 5 attempt in less than 10 minutes
ctf_modebase.flag_attempt_streaks = {
	[3] = "three",
	[4] = "four",
	[5] = "mega",
	[7] = "mega",
	[8] = "giga",
	[10] = "giga",
	[12] = "tera",
	[14] = "EXA",
}

local function drop_flags(player, pteam)
	local pname = player:get_player_name()
	local flagteams = ctf_modebase.taken_flags[pname]
	if not flagteams then return end

	for _, flagteam in ipairs(flagteams) do
		ctf_modebase.flag_taken[flagteam] = nil

		local fpos = vector.offset(ctf_map.current_map.teams[flagteam].flag_pos, 0, 1, 0)

		minetest.load_area(fpos)
		local node = minetest.get_node(fpos)

		if node.name == "ctf_modebase:flag_captured_top" then
			node.name = "ctf_modebase:flag_top_" .. flagteam
			minetest.set_node(fpos, node)
		else
			minetest.log("error", string.format("[ctf_flags] Unable to return flag node=%s, pos=%s",
				node.name, vector.to_string(fpos))
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

		if not ctf_modebase.match_started then return end

		if not ctf_modebase.taken_flags[pname] then
			ctf_modebase.taken_flags[pname] = {}
		end
		table.insert(ctf_modebase.taken_flags[pname], target_team)
		ctf_modebase.flag_taken[target_team] = {p=pname, t=pteam}

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

			if total_time >= 60*10 then
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

		if number_of_attempts > 14 then
			number_of_attempts = 14
		end

		local streak = ctf_modebase.flag_attempt_streaks[number_of_attempts]
		if streak then
			ctf_modebase.player_on_flag_attempt_streak[pname] = number_of_attempts

			minetest.chat_send_all(minetest.colorize(ctf_teams.team[pteam].color,  pname) ..
				minetest.colorize("#02e7fc",  " is on a " .. streak .. " attempt streak!"))
		end

		player_api.set_texture(puncher, 2,
			"default_wood.png^([combine:16x16:4,0=wool_white.png^[colorize:"..ctf_teams.team[target_team].color..":200)"
		)

		ctf_modebase.skip_vote.on_flag_take()
		ctf_modebase:get_current_mode().on_flag_take(puncher, target_team)

		RunCallbacks(ctf_api.registered_on_flag_take, puncher, target_team)

		minetest.set_node(nodepos, {name = "ctf_modebase:flag_captured_top", param2 = node.param2})
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
		player_api.set_texture(minetest.get_player_by_name(pname), 2, "blank.png")
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

minetest.register_on_dieplayer(function(player)
	ctf_modebase.drop_flags(player)
end)

minetest.register_on_leaveplayer(function(player)
	ctf_modebase.drop_flags(player)
end)
