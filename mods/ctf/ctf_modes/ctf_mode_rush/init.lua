local rankings = ctf_rankings.init()
local recent_rankings = ctf_modebase.recent_rankings(rankings)
local features = ctf_modebase.features(rankings, recent_rankings)

local MAX_REVIVES = 1

local modpath = core.get_modpath(core.get_current_modname())
local timer = dofile(modpath .. "/timer.lua")
local spectator = dofile(modpath .. "/spectator.lua")

ctf_mode_rush = ctf_mode_rush or {}
local rush_api = ctf_mode_rush

local state = {
	revives_left = {},
	eliminated = {},
	initial_team = {},
	participants = {},
	alive_players = {},
	team_defeated = {},
	saved_privs = {},
	vanish_active = {},
	winner_announced = false,
	match_id = nil,
	spectator_anchor = {},
	hud_handles = {},
	round_time_left = 0,
	round_timer_active = false,
}

local function reset_state()
	state.revives_left = {}
	state.eliminated = {}
	state.initial_team = {}
	state.participants = {}
	state.alive_players = {}
	state.team_defeated = {}
	state.saved_privs = {}
	state.vanish_active = {}
	state.winner_announced = false
	state.match_id = nil
	state.spectator_anchor = {}

	timer.reset()
	spectator.reset()
end

timer.setup({
	state = state,
	is_mode_active = function()
		return ctf_modebase.current_mode == "rush"
	end,
})

spectator.setup({
	state = state,
	timer = timer,
	rankings = rankings,
	recent_rankings = recent_rankings,
})

local function new_match_id()
	return tostring(core.get_us_time())
end

local function store_initial_team(pname, team)
	if not team or team == "" then
		state.initial_team[pname] = nil
		return
	end

	if state.initial_team[pname] and state.eliminated[pname] then
		return
	end

	state.initial_team[pname] = team
end

local function get_alive_teams()
    local alive = {}
    for team, players in pairs(state.alive_players) do
        if state.team_defeated[team] then goto continue end
        local real_alive = {}
        for pname in pairs(players) do
            local p = core.get_player_by_name(pname)
            if p and p:get_hp() > 0 and not is_elysium_player(pname) then
                real_alive[pname] = true
            end
        end
        state.alive_players[team] = real_alive  -- Cleanup: Entferne Elysium-Spieler
        if next(real_alive) then
            table.insert(alive, team)
        else
            announce_team_defeat(team)
            spectator.reassign_team_spectators(team)
            timer.update_round_huds()
            check_for_winner(team)  -- Explizit triggern für sofortiges Ende
        end
        ::continue::
    end
    return alive
end

local function update_flag_huds()
	for _, player in ipairs(core.get_connected_players()) do
		ctf_modebase.flag_huds.update_player(player)
	end
end

local function is_elysium_player(name)
	return ctf_jma_elysium and ctf_jma_elysium.get_player(name) ~= nil
end

local function award_score(name, score)
	recent_rankings.add(name, { score = score }, true)
end

local function announce_team_defeat(team)
	if state.team_defeated[team] then
		return
	end

	state.team_defeated[team] = true
	ctf_modebase.flag_captured[team] = true
	ctf_modebase.flag_taken[team] = nil

	local color = ctf_teams.team[team] and ctf_teams.team[team].color or "white"
	local message =
		core.colorize(color, HumanReadable(team) .. " base has been defeated!")
	core.chat_send_all(message)

	update_flag_huds()
end

local function declare_winner(team)
	if state.winner_announced then
		return
	end
	state.winner_announced = true
	timer.stop_round()

	local connected = core.get_connected_players()
	local winner_text

	if team then
		local color = ctf_teams.team[team] and ctf_teams.team[team].color or "white"
		winner_text = HumanReadable(team) .. " Team Wins!"
		core.chat_send_all(core.colorize(color, winner_text))
	else
		winner_text = "No team survived!"
		core.chat_send_all(core.colorize("orange", winner_text))
	end

	local score_per_survivor = 0
	local survivor_count = 0
	if team then
		for _ in pairs(state.alive_players[team]) do
			survivor_count = survivor_count + 1
		end
		if survivor_count > 0 then
			score_per_survivor = math.floor(500 / survivor_count)
		end
	end

	for name in pairs(state.participants) do
		if
			team
			and state.initial_team[name] == team
			and state.eliminated[name] ~= true
		then
			award_score(name, score_per_survivor)
		else
			award_score(name, 50)
		end
	end

	ctf_modebase.summary.set_winner(winner_text)

	local match_rankings, special_rankings, rank_values, formdef =
		ctf_modebase.summary.get()
	if formdef then
		formdef.title = winner_text
	end

	if match_rankings then
		for _, player in ipairs(connected) do
			ctf_modebase.summary.show_gui(
				player:get_player_name(),
				match_rankings,
				special_rankings,
				rank_values,
				formdef
			)
		end
	end

	ctf_modebase.start_new_match(5)
end

local function end_round_due_to_time()
	if state.winner_announced then
		return
	end

	local counts = timer.get_alive_counts()
	local best_team = nil
	local best_count = -1
	local tie = false

	for _, team_name in ipairs(ctf_teams.teamlist) do
		local count = counts[team_name]
		if count then
			if count > best_count then
				best_team = team_name
				best_count = count
				tie = false
			elseif count == best_count then
				tie = true
			end
		end
	end

	if not best_team or best_count <= 0 or tie then
		declare_winner(nil)
	else
		declare_winner(best_team)
	end
end

timer.set_timeout_handler(end_round_due_to_time)

ctf_api.register_on_match_start(function()
	if ctf_modebase.current_mode ~= "rush" or not state.match_id or state.round_timer_active then
		return
	end

	timer.start_round(timer.ROUND_DURATION)
end)

local function check_for_winner(team)
	local alive = state.alive_players[team]
	if not alive or next(alive) then
		return
	end

	announce_team_defeat(team)
	spectator.reassign_team_spectators(team)
	timer.update_round_huds()

	local alive_teams = get_alive_teams()
	if #alive_teams <= 1 then
		declare_winner(alive_teams[1])
	end
end

local function remove_flags()
	if not ctf_map.current_map then
		return
	end

	for _, teamdef in pairs(ctf_map.current_map.teams or {}) do
		if teamdef.flag_pos then
			local base_pos = vector.new(teamdef.flag_pos)
			local top_pos = vector.add(base_pos, { x = 0, y = 1, z = 0 })

			local node = core.get_node_or_nil(base_pos)
			if node and node.name ~= "air" then
				core.swap_node(base_pos, { name = "air" })
			end

			local top_node = core.get_node_or_nil(top_pos)
			if top_node and top_node.name ~= "air" then
				core.swap_node(top_pos, { name = "air" })
			end
		end
	end
end

local function init_alive_players()
	state.alive_players = {}
	state.team_defeated = {}

	if not ctf_map.current_map then
		return
	end

	for team in pairs(ctf_map.current_map.teams) do
		state.alive_players[team] = {}
		state.team_defeated[team] = false
		ctf_modebase.flag_captured[team] = nil
		ctf_modebase.flag_taken[team] = nil
	end
end

local function restore_all_players()
	for name, _ in pairs(state.participants) do
		if is_elysium_player(name) then
			state.participants[name] = nil
			state.eliminated[name] = nil
			state.alive_players[ctf_teams.get(name)] = nil  -- Cleanup
		end
	end
	for _, player in ipairs(core.get_connected_players()) do
		local name = player:get_player_name()
		spectator.restore_privs(name)
		spectator.disable_vanish(player)
		if state.initial_team[name] then
			ctf_teams.non_team_players[name] = nil
		end
		state.eliminated[name] = nil
		state.spectator_anchor[name] = nil
		state.revives_left[name] = nil
		timer.clear_round_hud(name)
		spectator.set_spectator_state(name, nil)
	end
	state.match_id = nil
	state.spectator_anchor = {}
	timer.reset()
	spectator.reset()
end

local function is_rush_active()
	return ctf_modebase.current_mode == "rush"
end

ctf_modebase.register_mode("rush", {
	hp_regen = 0.3,
	physics = { sneak_glitch = true, new_move = true },
	flag_hud_labels = {
		noun = "base",
		captured = "defeated",
	},
	vote_title_suffix = " (Test Phase)",
	vote_max_rounds = 0,
	treasures = {
		["default:cobble"] = {
			min_count = 30,
			max_count = 99,
			rarity = 0.25,
			max_stacks = 2,
		},
		["default:wood"] = {
			min_count = 20,
			max_count = 80,
			rarity = 0.25,
			max_stacks = 2,
		},
		["default:ladder_wood"] = {
			max_count = 16,
			rarity = 0.35,
			max_stacks = 4,
		},
		["default:torch"] = {
			max_count = 20,
			rarity = 0.3,
			max_stacks = 4,
		},
		["default:pick_steel"] = { rarity = 0.35, max_stacks = 2 },
		["ctf_melee:sword_steel"] = { rarity = 0.25, max_stacks = 2 },
		["ctf_melee:sword_mese"] = { rarity = 0.08, max_stacks = 1 },
		["ctf_ranged:pistol_loaded"] = { rarity = 0.25, max_stacks = 2 },
		["ctf_ranged:rifle_loaded"] = { rarity = 0.2, max_stacks = 1 },
		["ctf_ranged:shotgun_loaded"] = { rarity = 0.1, max_stacks = 1 },
		["ctf_ranged:assault_rifle_loaded"] = { rarity = 0.08, max_stacks = 1 },
		["ctf_ranged:ammo"] = {
			min_count = 3,
			max_count = 12,
			rarity = 0.3,
			max_stacks = 2,
		},
		["ctf_healing:bandage"] = {
			min_count = 1,
			max_count = 3,
			rarity = 0.35,
			max_stacks = 2,
		},
		["ctf_healing:medkit"] = { rarity = 0.07, max_stacks = 1 },
		["grenades:frag"] = { rarity = 0.18, max_stacks = 2 },
		["grenades:smoke"] = { rarity = 0.2, max_stacks = 2 },
		["wind_charges:wind_charge"] = {
			min_count = 3,
			max_count = 6,
			rarity = 0.25,
			max_stacks = 1,
		},
		["default:apple"] = {
			min_count = 4,
			max_count = 12,
			rarity = 0.25,
			max_stacks = 2,
		},
		["ctf_landmine:landmine"] = {
			min_count = 1,
			max_count = 4,
			rarity = 0.12,
			max_stacks = 1,
		},
		["boats:boat"] = { min_count = 1, max_count = 1, rarity = 0.05, max_stacks = 1 },
	},
	team_chest_items = {
		"default:cobble 80",
		"default:wood 80",
		"default:torch 30",
		"ctf_teams:door_steel 2",
		"ctf_healing:heal_block",
	},
	rankings = rankings,
	recent_rankings = recent_rankings,
	summary_ranks = {
		_sort = "score",
		"score",
		"kills",
		"kill_assists",
		"deaths",
		"hp_healed",
	},
	stuff_provider = function()
		return {
			"default:sword_steel",
			"default:pick_steel",
			"default:torch 20",
			"teleport_coin:coin",
		}
	end,
	initial_stuff_item_levels = features.initial_stuff_item_levels,
	on_mode_start = function()
		reset_state()
	end,
	on_mode_end = function()
		restore_all_players()
	end,
	on_new_match = function()
		reset_state()
		features.on_new_match()

		state.match_id = new_match_id()
		init_alive_players()

		core.after(0, function()
			remove_flags()
			update_flag_huds()
			timer.update_round_huds()
		end)
		for team in pairs(state.alive_players) do
			for pname in pairs(state.alive_players[team]) do
				if is_elysium_player(pname) then
					state.alive_players[team][pname] = nil
				end
			end
		end
	end,
	on_match_end = function()
		restore_all_players()
		reset_state()
		features.on_match_end()
	end,
	team_allocator = function(player)
		local name
		if type(player) == "string" then
			name = player
		elseif player and player.is_player and player:is_player() then
			name = player:get_player_name()
		end
		if not name or is_elysium_player(name) then
			return
		end
		if state.eliminated[name] then
			return
		end
		return features.team_allocator(player)
	end,
	on_allocplayer = function(player, new_team, old_team)
		local pname = player and player:get_player_name()
		if not pname or is_elysium_player(pname) then
			return
		end
		state.participants[pname] = true
		if old_team and state.alive_players[old_team] then
			state.alive_players[old_team][pname] = nil
			state.spectator_anchor[pname] = nil
			if not state.team_defeated[old_team] and not next(state.alive_players[old_team]) then
				check_for_winner(old_team)
			else
				timer.update_round_huds()
			end
			spectator.reassign_team_spectators(old_team)
		end
		store_initial_team(pname, new_team)

		if state.eliminated[pname] then
			core.after(0, function()
				local current = core.get_player_by_name(pname)
				if current then
					spectator.make_spectator(current)
					hud_events.new(pname, {
						text = "You have no revives left and are spectating this round.",
						color = "warning",
						quick = true,
					})
				end
			end)
			return
		end

		local revives = state.revives_left[pname]
		if revives == nil then
			revives = MAX_REVIVES
		end
		state.revives_left[pname] = revives

		state.alive_players[new_team] = state.alive_players[new_team] or {}
		state.alive_players[new_team][pname] = true

		spectator.restore_privs(pname)
		spectator.disable_vanish(player)
		spectator.reassign_team_spectators(new_team)
		timer.update_round_huds()

		features.on_allocplayer(player, new_team)
	end,
	on_leaveplayer = function(player)
		local pname = player and player:get_player_name()
		if not pname then return end
		local team = state.initial_team[pname]
		if is_elysium_player(pname) then
			if team and state.alive_players[team] then
				state.alive_players[team][pname] = nil
				if not next(state.alive_players[team]) then
					check_for_winner(team)
				end
			end
			state.participants[pname] = nil
			return
		end

		if team and state.alive_players[team] then
			state.alive_players[team][pname] = nil
		end

		if not state.eliminated[pname] then
			state.eliminated[pname] = nil
		end

		state.spectator_anchor[pname] = nil
		state.vanish_active[pname] = nil
		timer.clear_round_hud(pname)

		if team then
			spectator.reassign_team_spectators(team)
		end

		if team and state.alive_players[team] and not state.team_defeated[team] then
			if not next(state.alive_players[team]) then
				check_for_winner(team)
			end
		end

		timer.update_round_huds()
		features.on_leaveplayer(player)
	end,
	on_dieplayer = function(player, reason)
		local pname = player:get_player_name()
		local team = ctf_teams.get(pname)

		local revives = state.revives_left[pname]
		if revives == nil then
			revives = MAX_REVIVES
			state.revives_left[pname] = revives
		end

		revives = revives - 1
		state.revives_left[pname] = revives

		if revives >= 0 then
			if revives == 0 then
				hud_events.new(pname, {
					text = "Last life! Stay alive!",
					color = "warning",
					quick = true,
				})
			else
				hud_events.new(pname, {
					text = string.format("%d revives remaining", revives),
					color = "info",
					quick = true,
				})
			end
		else
			state.eliminated[pname] = true
			if team and state.alive_players[team] then
				state.alive_players[team][pname] = nil
				spectator.reassign_team_spectators(team)
			end
			hud_events.new(pname, {
				text = "You are out of revives! Spectating after respawn...",
				color = "warning",
				quick = true,
			})
		end

		if revives < 0 then
			timer.update_round_huds()
		end

		features.on_dieplayer(player, reason)

		if revives < 0 and team then
			check_for_winner(team)
		end
	end,
	on_respawnplayer = function(player)
		local pname = player:get_player_name()

		if state.eliminated[pname] then
			core.after(0, function()
				local p = core.get_player_by_name(pname)
				if not p then
					return
				end
				spectator.make_spectator(p)
				hud_events.new(pname, {
					text = "Spectating — thanks for playing!",
					color = "info",
					quick = true,
				})
			end)
			return
		end

		features.on_respawnplayer(player)

		local revives = state.revives_left[pname]
		if revives then
			local text
			local color = "info"

			if revives == 0 then
				text = "Last life! No revives remaining."
				color = "warning"
			else
				text = string.format("%d revives remaining", revives)
			end

			hud_events.new(pname, {
				text = text,
				color = color,
				quick = true,
			})
		end
	end,
	on_healplayer = features.on_healplayer,
	can_punchplayer = features.can_punchplayer,
	on_punchplayer = features.on_punchplayer,
	player_is_pro = features.player_is_pro,
	can_take_flag = function()
		return false
	end,
	on_flag_take = function() end,
	on_flag_drop = function() end,
	on_flag_capture = function() end,
	on_flag_rightclick = function() end,
	get_item_value = features.get_item_value,
	get_chest_access = features.get_chest_access,
})

core.register_globalstep(function(dtime)
	if ctf_modebase.current_mode ~= "rush" then
		return
	end

	timer.on_globalstep(dtime)
	spectator.on_globalstep(dtime)
end)

core.register_globalstep(function(dtime)
    if ctf_modebase.current_mode ~= "rush" then return end
    timer.on_globalstep(dtime)
    spectator.on_globalstep(dtime)

    -- Neu: Periodischer Elysium-Check (alle 5s)
    state.globalstep_timer = (state.globalstep_timer or 0) + dtime
    if state.globalstep_timer >= 5 then
        state.globalstep_timer = 0
        get_alive_teams()  -- Trigger Alive-Check
        local alive_teams = get_alive_teams()
        if #alive_teams <= 1 then
            declare_winner(alive_teams[1])
        end
    end
end)

core.register_on_joinplayer(function(player)
    local name = player:get_player_name()
    if is_elysium_player(name) then
        spectator.restore_privs(name)
        spectator.disable_vanish(player)
        state.eliminated[name] = nil
        state.participants[name] = nil
        return
    end
    local spec_state = spectator.get_spectator_state(name)
    if not spec_state or not spec_state.match then return end
    if not is_rush_active() or not state.match_id or spec_state.match ~= state.match_id then
        spectator.restore_privs(name)
        return
    end

	if type(spec_state.team) == "string" and spec_state.team ~= "" then
		state.initial_team[name] = spec_state.team
	end

	if spec_state.privs and not state.saved_privs[name] then
		state.saved_privs[name] = spec_state.privs
	end

	state.participants[name] = true
	state.vanish_active[name] = nil
	state.eliminated[name] = true
	state.spectator_anchor[name] = nil
	ctf_teams.remove_online_player(name)
	ctf_teams.player_team[name] = nil
	ctf_teams.non_team_players[name] = true

	local match_id = spec_state.match

	core.after(0, function()
		if
			not is_rush_active()
			or state.match_id ~= match_id
			or not state.eliminated[name]
		then
			return
		end

		local current = core.get_player_by_name(name)
		if not current then
			return
		end

		spectator.make_spectator(current)
	end)

	hud_events.new(name, {
		text = "You have no revives left and are spectating this round.",
		color = "warning",
		quick = true,
	})
end)

rush_api.is_spectator = spectator.is_spectator
rush_api.for_each_spectator = spectator.for_each_spectator
rush_api.get_match_id = function()
	return state.match_id
end
rush_api._state = state
