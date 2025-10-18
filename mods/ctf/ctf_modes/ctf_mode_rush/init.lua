local rankings = ctf_rankings.init()
local recent_rankings = ctf_modebase.recent_rankings(rankings)
local features = ctf_modebase.features(rankings, recent_rankings)

local MAX_REVIVES = 2
local RUSH_SPEC_KEY = "ctf_mode_rush:spectator_state"
local ROUND_DURATION = 120
local HUD_UPDATE_INTERVAL = 0.5
local MAX_SPECTATOR_DISTANCE = 12
local MIN_SPECTATOR_ALTITUDE = 2
local SPECTATOR_BOUND_CHECK_INTERVAL = 0.5
local SPECTATOR_CHAT_COLOR = "#8f7bb9"

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
	state.spectator_anchor = {}
	state.hud_handles = {}
	state.round_time_left = 0
	state.round_timer_active = false
end

local function new_match_id()
	return tostring(minetest.get_us_time())
end

local function safe_deserialize(data)
	if data == "" then
		return
	end

	local ok, value = pcall(minetest.deserialize, data)
	if ok then
		return value
	end
end

local function get_spectator_state(meta)
	local raw = meta:get_string(RUSH_SPEC_KEY)
	if raw == "" then
		return
	end

	local parsed = safe_deserialize(raw)
	if type(parsed) ~= "table" then
		return
	end

	if type(parsed.privs) ~= "table" then
		parsed.privs = {}
	end

	return parsed
end

local function set_spectator_state(meta, data)
	if not data or (not data.match and (not data.privs or next(data.privs) == nil)) then
		meta:set_string(RUSH_SPEC_KEY, "")
		return
	end

	local payload = {
		match = data.match,
		privs = data.privs,
	}

	meta:set_string(RUSH_SPEC_KEY, minetest.serialize(payload))
end

local function clear_round_hud(name)
	local handle = state.hud_handles[name]
	if not handle then
		return
	end

	local player = minetest.get_player_by_name(name)
	if player then
		player:hud_remove(handle)
	end

	state.hud_handles[name] = nil
end

local function clear_all_round_huds()
	for name in pairs(state.hud_handles) do
		clear_round_hud(name)
	end
end

local function get_alive_counts()
	local counts = {}
	for team, players in pairs(state.alive_players) do
		local count = 0
		for _, alive in pairs(players) do
			if alive then
				count = count + 1
			end
		end
		counts[team] = count
	end
	return counts
end

local function format_round_hud_text()
	if not state.match_id then
		return ""
	end

	local time_left = math.max(0, state.round_time_left or 0)
	local minutes = math.floor(time_left / 60)
	local seconds = math.floor(time_left % 60)
	local time_line = string.format("Time: %d:%02d", minutes, seconds)

	local counts = get_alive_counts()
	local team_parts = {}
	for _, team_name in ipairs(ctf_teams.teamlist) do
		if counts[team_name] then
			local label = HumanReadable(team_name)
			table.insert(team_parts, string.format("%s: %d", label, counts[team_name]))
		end
	end

	local teams_line = table.concat(team_parts, "  ")
	if teams_line ~= "" then
		return time_line .. "\n" .. teams_line
	end
	return time_line
end

local function update_round_hud_for_player(player)
	local pname = player:get_player_name()
	local text = format_round_hud_text()
	if text == "" then
		clear_round_hud(pname)
		return
	end

	local handle = state.hud_handles[pname]
	if not handle then
		handle = player:hud_add({
			type = "text",
			position = { x = 1, y = 1 },
			offset = { x = -20, y = -80 },
			alignment = { x = -1, y = -1 },
			number = 0xFFFFFF,
			scale = { x = 100, y = 100 },
			text = text,
		})
		state.hud_handles[pname] = handle
	else
		player:hud_change(handle, "text", text)
	end
end

local function update_round_huds()
	if ctf_modebase.current_mode ~= "rush" or not state.match_id then
		clear_all_round_huds()
		return
	end

	for _, player in ipairs(minetest.get_connected_players()) do
		update_round_hud_for_player(player)
	end
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

local function restore_privs(name, player)
	local privs = state.saved_privs[name]
	local ref = player or minetest.get_player_by_name(name)

	if not privs and ref then
		local spec_state = get_spectator_state(ref:get_meta())
		if spec_state then
			privs = spec_state.privs
		end
	end

	if not privs then
		privs = minetest.get_player_privs(name)
	end

	minetest.set_player_privs(name, privs)
	state.saved_privs[name] = nil

	if ref then
		set_spectator_state(ref:get_meta(), nil)
	end
end

local function remove_player_from_team(name)
	ctf_teams.remove_online_player(name)
	ctf_teams.player_team[name] = nil
	ctf_teams.non_team_players[name] = true
end

local function is_spectator(name)
	return state.eliminated[name] == true
end

local function for_each_spectator(callback)
	for pname, eliminated in pairs(state.eliminated) do
		if eliminated then
			callback(pname)
		end
	end
end

local function get_player_score(pname)
	local rec = recent_rankings.get(pname)
	if rec and rec.score then
		return rec.score
	end

	local overall = rankings:get(pname)
	if overall and overall.score then
		return overall.score
	end

	return 0
end

local function select_anchor_for_team(team)
	local alive = state.alive_players[team]
	if not alive then
		return nil
	end

	local best_player
	local best_score = -math.huge

	for pname in pairs(alive) do
		local player_obj = minetest.get_player_by_name(pname)
		if player_obj and player_obj:get_hp() > 0 then
			local score = get_player_score(pname)
			if score > best_score then
				best_score = score
				best_player = pname
			end
		end
	end

	return best_player
end

local function place_spectator_near_anchor(player)
	local pname = player:get_player_name()
	local anchor_name = state.spectator_anchor[pname]
	if not anchor_name then
		return
	end

	local anchor = minetest.get_player_by_name(anchor_name)
	if not anchor then
		return
	end

	local anchor_pos = anchor:get_pos()
	if not anchor_pos then
		return
	end

	local offset = {
		x = math.random(-3, 3),
		y = MIN_SPECTATOR_ALTITUDE + 2,
		z = math.random(-3, 3),
	}

	player:set_pos(vector.add(anchor_pos, offset))
end

local function assign_spectator_anchor(pname)
	local team = state.initial_team[pname]
	if not team then
		state.spectator_anchor[pname] = nil
		return nil
	end

	local previous = state.spectator_anchor[pname]
	local anchor = select_anchor_for_team(team)
	state.spectator_anchor[pname] = anchor

	if anchor and anchor ~= previous then
		local msg = string.format("Spectating %s. Stay within %d nodes.", anchor, MAX_SPECTATOR_DISTANCE)
		minetest.chat_send_player(pname, minetest.colorize(SPECTATOR_CHAT_COLOR, msg))
		local player = minetest.get_player_by_name(pname)
		if player then
			place_spectator_near_anchor(player)
		end
	elseif not anchor and previous then
		minetest.chat_send_player(pname, minetest.colorize(SPECTATOR_CHAT_COLOR, "No teammates available to spectate."))
	end

	return anchor
end

local function reassign_team_spectators(team)
	for pname, eliminated in pairs(state.eliminated) do
		if eliminated and state.initial_team[pname] == team then
			assign_spectator_anchor(pname)
		end
	end
end

local function enforce_spectator_bounds(pname)
	local spectator = minetest.get_player_by_name(pname)
	if not spectator then
		return
	end

	local team = state.initial_team[pname]
	if not team then
		return
	end

	local anchor_name = state.spectator_anchor[pname]
	if not anchor_name or not (state.alive_players[team] and state.alive_players[team][anchor_name]) then
		anchor_name = assign_spectator_anchor(pname)
	end

	if not anchor_name then
		return
	end

	local anchor = minetest.get_player_by_name(anchor_name)
	if not anchor then
		anchor_name = assign_spectator_anchor(pname)
		if not anchor_name then
			return
		end
		anchor = minetest.get_player_by_name(anchor_name)
		if not anchor then
			return
		end
	end

	local best_now = select_anchor_for_team(team)
	if best_now and best_now ~= anchor_name then
		anchor_name = assign_spectator_anchor(pname)
		if not anchor_name then
			return
		end
		anchor = minetest.get_player_by_name(anchor_name)
		if not anchor then
			return
		end
	end

	local anchor_pos = anchor:get_pos()
	local spec_pos = spectator:get_pos()
	if not anchor_pos or not spec_pos then
		return
	end

	local displacement = vector.subtract(spec_pos, anchor_pos)
	local distance = vector.length(displacement)

	if distance <= MAX_SPECTATOR_DISTANCE then
		return
	end

	if distance == 0 then
		displacement = { x = MAX_SPECTATOR_DISTANCE, y = MIN_SPECTATOR_ALTITUDE + 1, z = 0 }
	else
		displacement = vector.multiply(displacement, MAX_SPECTATOR_DISTANCE / distance)
	end

	if displacement.y < MIN_SPECTATOR_ALTITUDE then
		displacement.y = MIN_SPECTATOR_ALTITUDE
	end

	local target = vector.add(anchor_pos, displacement)
	spectator:set_pos(target)
end

local function disable_vanish(player)
	local name = player:get_player_name()

	if state.vanish_active[name] then
		vanish.off(player)
	end

	state.vanish_active[name] = nil
end

local function apply_vanish(player)
	local name = player:get_player_name()

	if state.vanish_active[name] then
		return
	end

	vanish.on(player, { pointable = false, is_visible = false })
	state.vanish_active[name] = true
end

local function make_spectator(player)
	local pname = player:get_player_name()
	local team = state.initial_team[pname]

	if team and state.alive_players[team] then
		state.alive_players[team][pname] = nil
	end
	update_round_huds()

	if state.eliminated[pname] ~= true then
		state.eliminated[pname] = true
	end

	if not state.saved_privs[pname] then
		state.saved_privs[pname] = minetest.get_player_privs(pname)
	end

	local privs = table.copy(state.saved_privs[pname])
	privs.interact = nil
	privs.fast = nil
	privs.fly = true
	privs.noclip = true

	minetest.set_player_privs(pname, privs)

	remove_player_from_team(pname)
	apply_vanish(player)
	assign_spectator_anchor(pname)
	place_spectator_near_anchor(player)

	player:set_hp(20)

	local meta = player:get_meta()
	set_spectator_state(meta, {
		match = state.match_id,
		privs = state.saved_privs[pname],
	})
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
	state.round_timer_active = false
	update_round_huds()

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
		if team and state.initial_team[name] == team and state.eliminated[name] ~= true then
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

	local counts = get_alive_counts()
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

local function check_for_winner(team)
	local alive = state.alive_players[team]
	if not alive or next(alive) then
		return
	end

	announce_team_defeat(team)
	reassign_team_spectators(team)
	update_round_huds()

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
		restore_privs(name, player)
		disable_vanish(player)
		if state.initial_team[name] then
			ctf_teams.non_team_players[name] = nil
		end
		state.eliminated[name] = nil
		state.spectator_anchor[name] = nil
		state.revives_left[name] = nil
		clear_round_hud(name)
		local meta = player:get_meta()
		set_spectator_state(meta, nil)
	end
	state.match_id = nil
	state.spectator_anchor = {}
	state.round_timer_active = false
	state.round_time_left = 0
	state.hud_handles = {}
end

local function is_rush_active()
	return ctf_modebase.current_mode == "rush"
end

local function trim(str)
	return (str:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function update_saved_priv_snapshot(target, modifier)
	local snapshot = state.saved_privs[target]

	if not snapshot then
		local player = minetest.get_player_by_name(target)
		if not player then
			return
		end

		local spec_state = get_spectator_state(player:get_meta())
		if not spec_state or not spec_state.match then
			return
		end

		snapshot = spec_state.privs
	end

	modifier(snapshot)

	state.saved_privs[target] = snapshot

	local player = minetest.get_player_by_name(target)
	if player then
		local meta = player:get_meta()
		local spec_state = get_spectator_state(meta) or {}
		spec_state.match = spec_state.match or state.match_id
		spec_state.privs = snapshot
		set_spectator_state(meta, spec_state)
	end
end

local function parse_priv_param(param)
	if not param then
		return
	end

	local target, payload = param:match("^(%S+)%s+(.+)$")
	if not target then
		return
	end

	payload = trim(payload)
	if payload == "" then
		return
	end

	if payload == "all" then
		return target, "all"
	end

	local privs = {}
	for token in payload:gmatch("[^,]+") do
		local priv = trim(token)
		if priv ~= "" then
			table.insert(privs, priv)
		end
	end

	if #privs == 0 then
		return
	end

	return target, privs
end

local function record_priv_change(target, privs, grant)
	if not privs then
		return
	end

	update_saved_priv_snapshot(target, function(snapshot)
		if privs == "all" then
			for name in pairs(minetest.registered_privileges) do
				if grant then
					snapshot[name] = true
				else
					snapshot[name] = nil
				end
			end
		else
			for _, priv in ipairs(privs) do
				if grant then
					snapshot[priv] = true
				else
					snapshot[priv] = nil
				end
			end
		end
	end)
end

local function parse_self_priv_param(param)
	if not param then
		return
	end

	param = trim(param)
	if param == "" then
		return
	end

	local privs = {}
	for token in param:gmatch("[^,]+") do
		local priv = trim(token)
		if priv ~= "" then
			table.insert(privs, priv)
		end
	end

	if #privs == 0 then
		return
	end

	return privs
end

local function create_priv_wrapper(is_grant, resolver)
	return function(original)
		return function(name, param)
			local ok, message = original(name, param)
			if ok then
				local target, privs = resolver(name, param)
				if target and privs then
					record_priv_change(target, privs, is_grant)
				end
			end
			return ok, message
		end
	end
end

minetest.after(0, function()
	local grant_wrapper = create_priv_wrapper(true, function(_, param)
		return parse_priv_param(param)
	end)
	local revoke_wrapper = create_priv_wrapper(false, function(_, param)
		return parse_priv_param(param)
	end)
	local grantme_wrapper = create_priv_wrapper(true, function(executor, param)
		local privs = parse_self_priv_param(param)
		if privs then
			return executor, privs
		end
	end)
	local revokeme_wrapper = create_priv_wrapper(false, function(executor, param)
		local privs = parse_self_priv_param(param)
		if privs then
			return executor, privs
		end
	end)

	local grant_def = minetest.registered_chatcommands.grant
	if grant_def and type(grant_def.func) == "function" then
		grant_def.func = grant_wrapper(grant_def.func)
	end

	local revoke_def = minetest.registered_chatcommands.revoke
	if revoke_def and type(revoke_def.func) == "function" then
		revoke_def.func = revoke_wrapper(revoke_def.func)
	end

	local grantme_def = minetest.registered_chatcommands.grantme
	if grantme_def and type(grantme_def.func) == "function" then
		grantme_def.func = grantme_wrapper(grantme_def.func)
	end

	local revokeme_def = minetest.registered_chatcommands.revokeme
	if revokeme_def and type(revokeme_def.func) == "function" then
		revokeme_def.func = revokeme_wrapper(revokeme_def.func)
	end

	local old_register_chatcommand = minetest.register_chatcommand
	function minetest.register_chatcommand(name, def)
		if name == "grant" and def and type(def.func) == "function" then
			def.func = grant_wrapper(def.func)
		elseif name == "revoke" and def and type(def.func) == "function" then
			def.func = revoke_wrapper(def.func)
		elseif name == "grantme" and def and type(def.func) == "function" then
			def.func = grantme_wrapper(def.func)
		elseif name == "revokeme" and def and type(def.func) == "function" then
			def.func = revokeme_wrapper(def.func)
		end
		return old_register_chatcommand(name, def)
	end

	local old_override_chatcommand = minetest.override_chatcommand
	function minetest.override_chatcommand(name, def)
		if name == "grant" and def and type(def.func) == "function" then
			def.func = grant_wrapper(def.func)
		elseif name == "revoke" and def and type(def.func) == "function" then
			def.func = revoke_wrapper(def.func)
		elseif name == "grantme" and def and type(def.func) == "function" then
			def.func = grantme_wrapper(def.func)
		elseif name == "revokeme" and def and type(def.func) == "function" then
			def.func = revokeme_wrapper(def.func)
		end
		return old_override_chatcommand(name, def)
	end
end)

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
		"heal_block:heal",
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
	state.round_time_left = ROUND_DURATION
	state.round_timer_active = true
	update_round_huds()

	minetest.after(0, function()
		remove_flags()
		update_flag_huds()
		update_round_huds()
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
					make_spectator(current)
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

	restore_privs(pname, player)
	disable_vanish(player)
	reassign_team_spectators(new_team)
	update_round_huds()

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
	clear_round_hud(pname)

	if team then
		reassign_team_spectators(team)
	end

	if team and state.alive_players[team] and not state.team_defeated[team] then
		if not next(state.alive_players[team]) then
			check_for_winner(team)
		end
	end

	update_round_huds()
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
			reassign_team_spectators(team)
		end
		hud_events.new(pname, {
			text = "You are out of revives! Spectating after respawn...",
			color = "warning",
			quick = true,
		})
	end
	if revives < 0 then
		update_round_huds()
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
				make_spectator(p)
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

local spectator_bound_timer = 0
local round_hud_timer = 0

minetest.register_globalstep(function(dtime)
	if ctf_modebase.current_mode ~= "rush" then
		return
	end

	if state.round_timer_active then
		state.round_time_left = math.max(0, (state.round_time_left or 0) - dtime)
		if state.round_time_left <= 0 then
			state.round_time_left = 0
			state.round_timer_active = false
			end_round_due_to_time()
		end
	end

	spectator_bound_timer = spectator_bound_timer + dtime
	if spectator_bound_timer >= SPECTATOR_BOUND_CHECK_INTERVAL then
		spectator_bound_timer = spectator_bound_timer - SPECTATOR_BOUND_CHECK_INTERVAL
		for pname, eliminated in pairs(state.eliminated) do
			if eliminated then
				enforce_spectator_bounds(pname)
			end
		end
	end

	round_hud_timer = round_hud_timer + dtime
	if round_hud_timer >= HUD_UPDATE_INTERVAL then
		round_hud_timer = 0
		update_round_huds()
	end
end)

minetest.register_on_joinplayer(function(player)
	local meta = player:get_meta()
	local spec_state = get_spectator_state(meta)
	if not spec_state or not spec_state.match then
		return
	end

	local name = player:get_player_name()

	if not is_rush_active() or not state.match_id or spec_state.match ~= state.match_id then
		restore_privs(name, player)
		return
	end

	--[[state.eliminated[name] = true
	state.saved_privs[name] = spec_state.privs
	ctf_teams.non_team_players[name] = true

	minetest.after(0, function()
		local current = minetest.get_player_by_name(name)
		if not current then
			return
		end

		make_spectator(current)
	end)]]
end)

rush_api.is_spectator = is_spectator
rush_api.for_each_spectator = for_each_spectator
rush_api.get_match_id = function()
	return state.match_id
end
rush_api._state = state
