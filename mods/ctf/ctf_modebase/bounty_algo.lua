ctf_modebase.bounty_algo = { kd = {} }
--- @type number
ctf_modebase.MIN_BOUNTY = 12

--- @param team_members string[]
--- @return string
function ctf_modebase.bounty_algo.kd.get_next_bounty(team_members)
	--- @type number
	local sum = 0
	--- @type number[]
	local kd_list = {}
	local recent = ctf_modebase:get_current_mode().recent_rankings.players()

	for _, pname in ipairs(team_members) do
		local kd = 0.1
		if recent[pname] then
			kd = math.max(kd, (recent[pname].kills or 0) / (recent[pname].deaths or 1))
		end

		table.insert(kd_list, kd)
		sum = sum + kd
	end

	--- @type number
	local random = math.random() * sum

	for i, kd in ipairs(kd_list) do
		--- @type number
		local bounty_score =
			ctf_modebase.bounty_algo.kd.bounty_reward_func(team_members[i]).score
		if random <= kd and bounty_score >= ctf_modebase.MIN_BOUNTY then
			return team_members[i]
		end
		random = random - kd
	end

	return team_members[#team_members]
end

--- @param pname string
--- @return { bounty_kills: integer, score: number }
function ctf_modebase.bounty_algo.kd.bounty_reward_func(pname)
	local recent = ctf_modebase:get_current_mode().recent_rankings.players()[pname] or {}
	local kd = (recent.kills or 1) / (recent.deaths or 1)

	return {
		bounty_kills = 1,
		score = math.max(ctf_modebase.MIN_BOUNTY, math.ceil(kd * 9)),
	}
end
