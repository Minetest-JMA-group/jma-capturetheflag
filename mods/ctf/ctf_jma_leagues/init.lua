ctf_jma_leagues = {
	leagues = dofile(minetest.get_modpath("ctf_jma_leagues") .. "/leagues.lua"),
	task_callbacks = {},
	on_promote_callbacks = {},
}

local modstorage = minetest.get_mod_storage()
local leagues_cache = {}
local player_ctx = {}
local storage_prefix = "current_league_"

function ctf_jma_leagues.register_task(task_type, callback)
	ctf_jma_leagues.task_callbacks[task_type] = callback
end

function ctf_jma_leagues.register_on_promote(callback)
	table.insert(ctf_jma_leagues.on_promote_callbacks, callback)
end

function ctf_jma_leagues.get_league(player_name)
	if leagues_cache[player_name] then
		return leagues_cache[player_name]
	end

	local league = modstorage:get_string(storage_prefix .. player_name)
	local l = league ~= "" and league or "none"
	leagues_cache[player_name] = l
	return l
end

function ctf_jma_leagues.check_requirements(player_name, league)
	for _, req in ipairs(league.requirements or {}) do
		local result = ctf_jma_leagues.evaluate_task(player_name, req)
		if not result.done then
			return false
		end
	end
	return true
end

function ctf_jma_leagues.evaluate_task(player_name, req)
	local cb = ctf_jma_leagues.task_callbacks[req.task_type]
	if not cb then
		return {done = false, error = "Callback missing"}
	end

	local pctx = player_ctx[player_name]
	if not pctx then
		pctx = {}
		player_ctx[player_name] = pctx
	end

	local result = cb(player_name, pctx, req.params)
	if type(result) == "boolean" then
		result = {done = result, current = result and req.params.goal or 0, required = req.params.goal}
	elseif type(result) ~= "table" or result.done == nil then
		result = {done = false, error = "Invalid callback result"}
		minetest.log("error", "Invalid callback result for task: " .. req.task_type)
	end

	return result
end

function ctf_jma_leagues.evaluate_progress(player_name, league)
    local results = {
        tasks = {},
        total_progress = 0,
        tasks_completed = 0,
        total_tasks = #league.requirements
    }

    for _, req in ipairs(league.requirements) do
        local result = ctf_jma_leagues.evaluate_task(player_name, req)
        table.insert(results.tasks, {
            requirement = req,
            result = result
        })

        if result.done then
            results.tasks_completed = results.tasks_completed + 1
            results.total_progress = results.total_progress + 100
        elseif result.get_progress then
            local task_progress = result.get_progress(result, req)
            results.total_progress = results.total_progress + math.floor(task_progress)
        elseif result.current and result.required then
            local task_progress = math.floor((result.current / result.required) * 100)
            results.total_progress = results.total_progress + task_progress
        end
    end

    results.total_percentage = results.total_tasks > 0 and (results.total_progress / results.total_tasks) or 100

    return results
end

function ctf_jma_leagues.get_next_league(player_name)
	local current = ctf_jma_leagues.get_league(player_name)
	local current_order = 0
	if current ~= "none" then
		current_order = ctf_jma_leagues.leagues[current].order
	end

	local next_league
	local promotion_possible = false
	for lname, league in pairs(ctf_jma_leagues.leagues) do
		if league.order == current_order + 1 then
			if ctf_jma_leagues.check_requirements(player_name, league) then
				promotion_possible = true
			end
			next_league = lname
			break
		end
	end
	return next_league, promotion_possible
end

function ctf_jma_leagues.update_league(player_name)
    local current = ctf_jma_leagues.get_league(player_name)
    while true do
        local next_league, promotion = ctf_jma_leagues.get_next_league(player_name)
        if not next_league or not promotion then
            break
        end

        modstorage:set_string(storage_prefix .. player_name, next_league)
        leagues_cache[player_name] = next_league

        local info = ctf_jma_leagues.leagues[next_league]
        if info then
            minetest.chat_send_all(
                minetest.colorize("#FFA500", "[Leagues]") ..
                minetest.colorize("#00FF00", string.format(
                    ": %s advanced the %s!",
                    player_name,
                    info.display_name
                ))
            )
            hpbar.set_icon(minetest.get_player_by_name(player_name), info.icon_texture)
        end

        for _, cb in ipairs(ctf_jma_leagues.on_promote_callbacks) do
            cb(player_name, current, next_league)
        end

        current = next_league
    end
end

function ctf_jma_leagues.reset_leaugue(player_name)
	local key = storage_prefix .. player_name
	if modstorage:contains(key) then
		modstorage:set_string(key, "")
	end
	leagues_cache[player_name] = nil
	local player = minetest.get_player_by_name(player_name)
	if player then
		hpbar.set_icon(player, "")
	end
	player_ctx[player_name] = nil
end

function ctf_jma_leagues.reset_all()
	modstorage:from_table({})
	leagues_cache = {}
	player_ctx = {}
end

function ctf_jma_leagues.flush_cache(player_name, force)
	if force or not minetest.get_player_by_name(player_name) then
		leagues_cache[player_name] = nil
		player_ctx[player_name] = nil
	end
end

local function update_icon(player)
	local info = ctf_jma_leagues.leagues[ctf_jma_leagues.get_league(player:get_player_name())]
	if info and info.icon_texture then
		hpbar.set_icon(player, info.icon_texture)
	end
end

ctf_api.register_on_match_end(function()
	minetest.after(1, function()
		for _, p in pairs(minetest.get_connected_players()) do
			local name = p:get_player_name()
			player_ctx[name] = {}
			ctf_jma_leagues.update_league(name)
			update_icon(p)
		end
	end)
end)

ctf_chat.register_prefix(1, function(name, tcolor)
	local league = ctf_jma_leagues.get_league(name)
	if league ~= "none" then
		local color = ctf_jma_leagues.leagues[league].color or "white"
		return minetest.colorize(color, "[" .. HumanReadable(league) .. "]")
	end
end)

minetest.register_on_joinplayer(function(player)
	local player_name = player:get_player_name()
	player_ctx[player_name] = {}
	ctf_jma_leagues.update_league(player_name)
	update_icon(player)
end)

minetest.register_on_leaveplayer(function(player)
	local player_name = player:get_player_name()
	leagues_cache[player_name] = nil
	player_ctx[player_name] = nil
end)

ctf_core.include_files("cmds.lua", "tasks.lua", "formspec.lua")
