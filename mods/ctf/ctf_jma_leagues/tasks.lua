local function get_mode_rankings(mode_name, player_name)
	local mode = ctf_modebase.modes[mode_name]
	return mode.rankings:get(player_name) or {}
end

local function collect(player_name)
	local res = {}
	local total = {kd = 0}

	for mode_name, _ in pairs(ctf_modebase.modes) do
		res[mode_name] = {}

		for k, v in pairs(get_mode_rankings(mode_name, player_name)) do
			res[mode_name][k] = v

			if not total[k] then
				total[k] = 0
			end
			total[k] = total[k] + v
		end
	end

	total.kd = total.kills and total.deaths and (total.kills / total.deaths)
	res.total = total
	return res
end

local tasks = {
	"score",
	"flag_captures",
	"kd",
	"kills",
	"deaths",
	"bounty_kills",
	"hp_healed",
	"kill_assists"
}

local function get_cached_rankings(ctx, player_name)
	local now = os.time()
	if not ctx.rankings or ctx.rankings.last_update < now - 5 then
		ctx.rankings = {
			last_update = now,
			data = collect(player_name)
		}
	end
	return ctx.rankings.data
end

for _, task_name in ipairs(tasks) do
	ctf_jma_leagues.register_task(task_name, function(player_name, ctx, params)
		local data = get_cached_rankings(ctx, player_name)
		local total_value = data[params.mode_name][task_name] or 0

		return {
			done = total_value >= params.goal,
			current = total_value,
			required = params.goal
		}
	end)
end

ctf_jma_leagues.register_task("top_pos", function(player_name, ctx, params)
	local best_position = math.huge
	local function find_best_pos(mode)
		if mode then
			local top_list = mode.rankings.top:get_top(params.range)
			for i, entry_name in ipairs(top_list) do
				if entry_name == player_name then
					if i < best_position then
						best_position = i
					end
					break
				end
			end
		end
	end

	if params.mode_name == "total" then
		for _, mode in pairs(ctf_modebase.modes) do
			find_best_pos(mode)
		end
	else
		find_best_pos(ctf_modebase.modes[params.mode_name])
	end

	if best_position == math.huge then
		return {
			done = false,
			current = nil,
			required = params.goal,
		}
	end

	local function get_progress(result, req)
		if result.current <= result.required then
			return 100
		end
		local range = req.params.range
		local required = result.required
		return math.max(0, 1 - (math.min(result.current, range) - required) / (range - required)) * 100
	end

	return {
		done = best_position <= params.goal,
		current = best_position,
		required = params.goal,
		get_progress = get_progress
	}
end)

ctf_jma_leagues.register_task("playtime", function(player_name, ctx, params)
	local time = playtime.get_total_playtime(player_name) or 0
	if time > 0 then
		time = math.floor(time / 60) -- Min
	end

	return {
		done = time >= params.goal,
		current = time,
		required = params.goal
	}
end)

for _, atype in ipairs({"bronze", "silver", "gold"}) do
	ctf_jma_leagues.register_task("acv_"..atype, function(player_name, ctx, params)
		local trophies = ctf_jma_achieves.count_trophies(player_name)[atype]
		return {
			done = trophies >= params.goal,
			current = trophies,
			required = params.goal
	}
	end)
end
