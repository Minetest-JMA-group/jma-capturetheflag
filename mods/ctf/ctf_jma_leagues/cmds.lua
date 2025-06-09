minetest.register_chatcommand("league", {
	params = "[player_name]",
	description = "Show league progress",
	func = function(name, param)
		local player_name = param ~= "" and param or name

		if not minetest.player_exists(player_name) then
			return false, "Player not found"
		end

		local league_info = ctf_jma_leagues.leagues[ctf_jma_leagues.get_league(player_name)]
		if not league_info or league_info  == "none" then
			return true, "Player has not reached any league yet"
		end
		local next_league = ctf_jma_leagues.get_next_league(player_name)
		if not next_league then
			ctf_jma_leagues.flush_cache(player_name)
			return true, string.format("%s's current league: %s (max league reached)",
				player_name, minetest.colorize(league_info.color, league_info.display_name))
		end

		local next_league_info = ctf_jma_leagues.leagues[next_league]
		local eval = ctf_jma_leagues.evaluate_progress(player_name, next_league_info)

		local msg = string.format(
			"%s is currently in %s\nProgress to %s: %d%% (%d/%d tasks completed)",
			player_name,
			minetest.colorize(league_info.color, league_info.display_name),
			minetest.colorize(next_league_info.color, next_league_info.display_name),
			math.floor(eval.total_percentage),
			eval.tasks_completed,
			eval.total_tasks
		)

		for _, task in ipairs(eval.tasks) do
			local req = task.requirement
			local result = task.result
			local status, progress
			if result.done then
				status = minetest.colorize("#00ff00", "✓")
				progress = string.format("%d/%d", result.required, result.required)
			elseif result.current and result.required then
				status = minetest.colorize("#ffff00", "•••")
				progress = string.format("%d/%d", result.current, result.required)
			elseif result.error then
				status = minetest.colorize("#ff0000", "x")
				progress = "Cannot be completed, please contact an admin"
			else
				status = minetest.colorize("#ff0000", "x")
				progress = "0/" .. tostring(result.required or "?")
			end
			msg = msg .. string.format("\n  %s %s [%s]", status, req.description, progress)
		end

		ctf_jma_leagues.flush_cache(player_name)
		return true, msg
	end
})

minetest.register_chatcommand("league_reset", {
	privs = {ctf_admin = true},
	params = "Reset all (danger!) with <!> or <player_name>",
	description = "Reset league progress",
	func = function(name, param)
		-- if param == "!" then
		-- 	ctf_jma_leagues.reset_all()
		-- 	return true, "All players league progress has been reset."
		-- end

		if minetest.player_exists(param) then
			if ctf_jma_leagues.get_league(param) == "none" then
				return false, "Player is not in any league, no need to reset"
			end
			ctf_jma_leagues.reset_leaugue(param)
			return true, "League progress for " .. param .. " has been reset."
		else
			return false, "Player not found"
		end
	end
})
