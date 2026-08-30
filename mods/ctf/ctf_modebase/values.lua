--- @alias ScoreFun fun(player: PlayerName, recent: number?): number
---
ctf_modebase.values = {}

--- @param player PlayerName
--- @param recent number?
--- @return table
function ctf_modebase.values.get_ranking(player, recent)
	recent = recent or 0.0
	local complement = 1.0 - recent
	local current_mode = ctf_modebase:get_current_mode()
	local ranking = {}
	local recent_rankings = {}
	if current_mode then
		ranking = current_mode.get_ranking(player)
		recent_rankings = current_mode.get_recent_ranking(player)
	end
	return {
		kills = (ranking.kills or 0) * complement + (recent_rankings.kills or 0) * recent,
		deaths = (ranking.deaths or 1) * complement
			+ (recent_rankings.deaths or 1) * recent,
		kill_assists = (ranking.kill_assists or 0) * complement
			+ (recent_rankings.kill_assists or 0) * recent,
		hp_healed = (ranking.hp_healed or 0) * complement
			+ (recent_rankings.hp_healed or 0) * recent,
		capture_coins = (ranking.capture_coins or 0) * complement
			+ (recent_rankings.capture_coins or 0) * recent,
		build_points = (ranking.build_points or 0) * complement
			+ (recent_rankings.build_points or 0) * recent,
	}
end

--- @type ScoreFun
function ctf_modebase.values.get_pvp_score(player, recent)
	local rankings = ctf_modebase.values.get_ranking(player, recent)
	local kills = rankings.kills or 0
	local deaths = rankings.deaths or 1
	local assists = rankings.kill_assists or 0
	return (kills + assists / 5) / deaths
end

--- @type ScoreFun
function ctf_modebase.values.get_build_point(player, recent)
	local ranking = ctf_modebase.values.get_ranking(player, recent)
	return ranking.build_points or 0
end

--- @type ScoreFun
function ctf_modebase.values.get_capture_coin(player, recent)
	--local ranking = get_ranking(player, recent)
	return 1
end

--- @type ScoreFun
function ctf_modebase.values.get_heal_score(player, recent)
	local ranking = ctf_modebase.values.get_ranking(player, recent)
	local hp_healed = ranking.hp_healed or 1
	local deaths = ranking.deaths or 1
	--- 30 is knight_hp / 2
	return math.sqrt(hp_healed / 30) / (deaths + 1)
end

--- @type ScoreFun
function ctf_modebase.values.get_player_active_value(player, recent)
	local pvp_score = ctf_modebase.values.get_pvp_score(player, recent)
	local capcoins = ctf_modebase.values.get_capture_coin(player, recent)
	core.debug(string.format("(pvp, ca, %f) = %f %f", recent or 1.0, pvp_score, capcoins))

	return pvp_score + capcoins + math.min(pvp_score, capcoins)
end

--- @type ScoreFun
function ctf_modebase.values.get_player_passive_value(player, recent)
	local heal_score = ctf_modebase.values.get_heal_score(player, recent)
	local build_score = ctf_modebase.values.get_build_point(player, recent)
	core.debug(
		string.format("(h, b, %f) = %f %f", recent or 1.0, heal_score, build_score)
	)
	return heal_score + build_score + math.min(heal_score, build_score)
end

--- @type ScoreFun
function ctf_modebase.values.get_player_value(player, recent)
	local passive_val = ctf_modebase.values.get_player_passive_value(player, recent)
	local active_val = ctf_modebase.values.get_player_active_value(player, recent)
	core.debug(string.format("(p,a) val of %s: %f, %f", player, passive_val, active_val))
	--- @type number
	local combined_val = math.pow(active_val * passive_val, 1.2)
	if math.isfinite and not math.isfinite(combined_val) then
		core.log(
			"warning",
			string.format(
				"Player value of %s is inf! Recent: %f P val: %f A val: %f",
				player,
				recent or 0.0,
				passive_val,
				active_val
			)
		)
		return 1
	end
	core.log("info", string.format("Value of %s is %.3f", player, combined_val))
	return combined_val
end

--- @param team_a Team
--- @param team_b Team
--- @param recent number?
--- @return number
function ctf_modebase.values.compare_team_values(team_a, team_b, recent)
	-- A team value equals product of values of team members.
	-- Here we compute ratio of team_a:team_b. However, a problem
	-- is that we cannot compute each product then divide them as it's
	-- likely that the number will overflow and become inf like in
	-- get_player_value. --Farooq

	recent = recent or 1.0
	--- @type PlayerName[]
	local team_a_members = ctf_teams.get_team_members(team_a)
	--- @type PlayerName[]
	local team_b_members = ctf_teams.get_team_members(team_b)
	--- @type integer
	local bigger_team_len = #team_a_members
	if #team_b_members > #team_a_members then
		bigger_team_len = #team_b_members
	end
	if #team_a_members == 0 or #team_b_members == 0 then
		return 1
	end
	--- @type number
	local teams_ratio = 1
	for i = 1, bigger_team_len do
		local player_a = team_a_members[i]
		local player_b = team_b_members[i]
		--- @type number
		local a_val = 1
		if player_a then
			a_val = ctf_modebase.values.get_player_value(player_a, recent)
		end
		--- @type number
		local b_val = 1
		if player_b then
			b_val = ctf_modebase.values.get_player_value(player_b, recent)
		end
		teams_ratio = (a_val / b_val) * teams_ratio
	end
	return teams_ratio
end

--- @param loser_teams Team[]
--- @param winner_team Team
--- @param other_teams Team[]?
--- @param flag_thief PlayerName
--- @return number
function ctf_modebase.values.calculate_capture_coins(
	loser_teams,
	winner_team,
	other_teams,
	flag_thief
)
	other_teams = other_teams or {}
	-- Comparing value of loser teams to thief's team
	--- @type number
	local ratios = 0
	--- @type integer
	local loser_team_members = 0
	for _, loser_team in ipairs(loser_teams) do
		ratios = ratios + ctf_modebase.values.compare_team_values(loser_team, winner_team)
		loser_team_members = loser_team_members + #ctf_teams.get_team_members(loser_team)
	end

	-- If there are other teams, they would likely try to kill the flag
	-- thief even tho it's not their flag. So we also count them use an average
	-- of all of them, and at the end, divide it by 2.

	--- @type number
	local other_teams_ratios_sum = 0
	--- @type number
	local other_teams_n = 0
	for _, other_team in pairs(other_teams) do
		local ratio_other =
			ctf_modebase.values.compare_team_values(other_team, winner_team)
		other_teams_ratios_sum = other_teams_ratios_sum + ratio_other
		other_teams_n = other_teams_n + 1
	end
	if other_teams_n > 0 then
		local average_other = other_teams_ratios_sum / other_teams_n
		ratios = ratios + average_other / other_teams_n
	end

	-- Now we also need active value of the thief which is
	-- capture skill and pvp skill combined. And we need to
	-- compare it to number of players in the loser team(s)
	--- @type number
	local thief_val = ctf_modebase.values.get_player_active_value(flag_thief, 0.5)

	--- @type integer
	local cap_coins = math.ceil(128 * ratios * loser_team_members / thief_val)

	core.debug("CapCoin Calculate")
	core.debug(string.format("AValue of %s is %f", flag_thief, thief_val))
	core.debug(
		string.format(
			"Ratio is %f and number of enemy tmembers is %d",
			ratios,
			loser_team_members
		)
	)
	core.debug(string.format("Capper %s got %d CapCoins", flag_thief, cap_coins))

	return math.max(cap_coins, 10)
end
