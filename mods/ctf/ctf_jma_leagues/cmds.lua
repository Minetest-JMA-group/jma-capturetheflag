minetest.register_chatcommand("league", {
	params = "[player_name]",
	description = "Show league progress",
	func = function(name, param)
		local player_name = param ~= "" and param or name

		if not minetest.player_exists(player_name) then
			return false, "Player not found"
		end

		local current = ctf_jma_leagues.get_league(player_name)
		local current_info = ctf_jma_leagues.leagues[current]
		local current_display = current_info and current_info.display_name or "No League"

		local next_league = ctf_jma_leagues.get_next_league(player_name)
		if not next_league then
			return true, string.format("%s's current league: %s (max league reached)",
				player_name, current_display)
		end

		local next_league_info = ctf_jma_leagues.leagues[next_league]
		local eval = ctf_jma_leagues.evaluate_progress(player_name, next_league_info)

		local msg = string.format(
			"%s's league: %s\nProgress towards %s: %d%% (%d/%d tasks complete)",
			player_name,
			current_display,
			next_league_info.display_name,
			math.floor(eval.total_percentage),
			eval.tasks_completed,
			eval.total_tasks
		)

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
