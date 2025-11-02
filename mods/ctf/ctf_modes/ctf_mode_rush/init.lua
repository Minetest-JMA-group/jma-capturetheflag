local rankings = ctf_rankings.init()
local recent_rankings = ctf_modebase.recent_rankings(rankings)
local features = ctf_modebase.features(rankings, recent_rankings)

local MAX_REVIVES = 2

local modpath = minetest.get_modpath(minetest.get_current_modname())
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
	return tostring(minetest.get_us_time())
end

local function store_initial_team(pname, team)
	if not state.initial_team[pname] then
		state.initial_team[pname] = team
	end
end

local function get_alive_teams()
	local alive = {}

	for team, players in pairs(state.alive_players) do
		if not state.team_defeated[team] and next(players) then
			table.insert(alive, team)
		end
	end

	return alive
end

local function update_flag_huds()
	for _, player in ipairs(minetest.get_connected_players()) do
		ctf_modebase.flag_huds.update_player(player)
	end
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
		minetest.colorize(color, HumanReadable(team) .. " base has been defeated!")
	minetest.chat_send_all(message)

	update_flag_huds()
end

local function declare_winner(team)
	if state.winner_announced then
		return
	end
	state.winner_announced = true
	timer.stop_round()

	local connected = minetest.get_connected_players()
	local winner_text

	if team then
		local color = ctf_teams.team[team] and ctf_teams.team[team].color or "white"
		winner_text = HumanReadable(team) .. " Team Wins!"
		minetest.chat_send_all(minetest.colorize(color, winner_text))
	else
		winner_text = "No team survived!"
		minetest.chat_send_all(minetest.colorize("orange", winner_text))
	end

	for name in pairs(state.participants) do
		if
			team
			and state.initial_team[name] == team
			and state.eliminated[name] ~= true
		then
			award_score(name, 500)
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

			local node = minetest.get_node_or_nil(base_pos)
			if node and node.name ~= "air" then
				minetest.swap_node(base_pos, { name = "air" })
			end

			local top_node = minetest.get_node_or_nil(top_pos)
			if top_node and top_node.name ~= "air" then
				minetest.swap_node(top_pos, { name = "air" })
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
	for _, player in ipairs(minetest.get_connected_players()) do
		local name = player:get_player_name()
		spectator.restore_privs(name, player)
		spectator.disable_vanish(player)
		if state.initial_team[name] then
			ctf_teams.non_team_players[name] = nil
		end
		state.eliminated[name] = nil
		state.spectator_anchor[name] = nil
		state.revives_left[name] = nil
		timer.clear_round_hud(name)
		local meta = player:get_meta()
		spectator.set_spectator_state(meta, nil)
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

		minetest.after(0, function()
			remove_flags()
			update_flag_huds()
			timer.update_round_huds()
		end)
	end,
	on_match_end = function()
		restore_all_players()
		reset_state()
		features.on_match_end()
	end,
	team_allocator = features.team_allocator,
	on_allocplayer = function(player, new_team)
		local pname = player:get_player_name()

		state.participants[pname] = true
		store_initial_team(pname, new_team)

		if state.eliminated[pname] then
			minetest.after(0, function()
				local current = minetest.get_player_by_name(pname)
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

		spectator.restore_privs(pname, player)
		spectator.disable_vanish(player)
		spectator.reassign_team_spectators(new_team)
		timer.update_round_huds()

		features.on_allocplayer(player, new_team)
	end,
	on_leaveplayer = function(player)
		local pname = player:get_player_name()
		local team = state.initial_team[pname]

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
			minetest.after(0, function()
				local p = minetest.get_player_by_name(pname)
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
	get_chest_access = features.get_chest_access,
})

minetest.register_globalstep(function(dtime)
	if ctf_modebase.current_mode ~= "rush" then
		return
	end

	timer.on_globalstep(dtime)
	spectator.on_globalstep(dtime)
end)

minetest.register_on_joinplayer(function(player)
	local meta = player:get_meta()
	local spec_state = spectator.get_spectator_state(meta)
	if not spec_state or not spec_state.match then
		return
	end

	local name = player:get_player_name()

	if
		not is_rush_active()
		or not state.match_id
		or spec_state.match ~= state.match_id
	then
		spectator.restore_privs(name, player)
		return
	end

	if spec_state.privs and not state.saved_privs[name] then
		state.saved_privs[name] = spec_state.privs
	end

	state.eliminated[name] = true
end)

rush_api.is_spectator = spectator.is_spectator
rush_api.for_each_spectator = spectator.for_each_spectator
rush_api.get_match_id = function()
	return state.match_id
end
rush_api._state = state
