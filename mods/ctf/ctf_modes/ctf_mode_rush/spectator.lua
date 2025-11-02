local spectator = {}

local RUSH_SPEC_KEY = "ctf_mode_rush:spectator_state"
local storage = minetest.get_mod_storage()

local function storage_key(name)
	if type(name) ~= "string" or name == "" then
		return
	end
	return RUSH_SPEC_KEY .. ":" .. name
end
local MAX_SPECTATOR_DISTANCE = 12
local MIN_SPECTATOR_ALTITUDE = 2
local SPECTATOR_BOUND_CHECK_INTERVAL = 0.5
local SPECTATOR_CHAT_COLOR = "#8f7bb9"

local state
local timer
local rankings
local recent_rankings

local bound_timer = 0
local priv_hooks_installed = false

local function ensure_state()
	if not state then
		error("ctf_mode_rush.spectator not initialised")
	end
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

function spectator.get_spectator_state(name)
	local key = storage_key(name)
	if not key then
		return
	end

	local raw = storage:get_string(key)
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

function spectator.set_spectator_state(name, data)
	local key = storage_key(name)
	if not key then
		return
	end

	if not data or (not data.match and (not data.privs or next(data.privs) == nil)) then
		storage:set_string(key, "")
		return
	end

	local payload = {
		match = data.match,
		privs = data.privs,
	}

	storage:set_string(key, minetest.serialize(payload))
end

local function get_player_score(pname)
	if recent_rankings then
		local rec = recent_rankings.get(pname)
		if rec and rec.score then
			return rec.score
		end
	end

	if rankings then
		local overall = rankings:get(pname)
		if overall and overall.score then
			return overall.score
		end
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
		local msg = string.format(
			"Spectating %s. Stay within %d nodes.",
			anchor,
			MAX_SPECTATOR_DISTANCE
		)
		minetest.chat_send_player(pname, minetest.colorize(SPECTATOR_CHAT_COLOR, msg))
		local player = minetest.get_player_by_name(pname)
		if player then
			place_spectator_near_anchor(player)
		end
	elseif not anchor and previous then
		minetest.chat_send_player(
			pname,
			minetest.colorize(SPECTATOR_CHAT_COLOR, "No teammates available to spectate.")
		)
	end

	return anchor
end

function spectator.reassign_team_spectators(team)
	ensure_state()

	for pname, eliminated in pairs(state.eliminated) do
		if eliminated and state.initial_team[pname] == team then
			assign_spectator_anchor(pname)
		end
	end
end

function spectator.enforce_spectator_bounds(pname)
	ensure_state()

	local spectator_obj = minetest.get_player_by_name(pname)
	if not spectator_obj then
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
	local spec_pos = spectator_obj:get_pos()
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
	spectator_obj:set_pos(target)
end

function spectator.disable_vanish(player)
	ensure_state()

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

local function remove_player_from_team(name)
	ctf_teams.remove_online_player(name)
	ctf_teams.player_team[name] = nil
	ctf_teams.non_team_players[name] = true
end

function spectator.restore_privs(name)
	ensure_state()

	local privs = state.saved_privs[name]
	if not privs then
		local spec_state = spectator.get_spectator_state(name)
		if spec_state then
			privs = spec_state.privs
		end
	end

	if not privs then
		privs = minetest.get_player_privs(name)
	end

	minetest.set_player_privs(name, privs)
	state.saved_privs[name] = nil
	spectator.set_spectator_state(name, nil)
end

function spectator.make_spectator(player)
	ensure_state()

	local pname = player:get_player_name()
	local team = state.initial_team[pname]

	if team and state.alive_players[team] then
		state.alive_players[team][pname] = nil
	end
	timer.update_round_huds()

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

	spectator.set_spectator_state(pname, {
		match = state.match_id,
		privs = state.saved_privs[pname],
	})
end

function spectator.is_spectator(name)
	ensure_state()
	return state.eliminated[name] == true
end

function spectator.for_each_spectator(callback)
	ensure_state()

	for pname, eliminated in pairs(state.eliminated) do
		if eliminated then
			callback(pname)
		end
	end
end

local function trim(str)
	return (str:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function update_saved_priv_snapshot(target, modifier)
	if not state.saved_privs then
		return
	end

	local snapshot = state.saved_privs[target]
	local spec_state

	if not snapshot then
		spec_state = spectator.get_spectator_state(target)
		if not spec_state or not spec_state.match then
			return
		end

		snapshot = spec_state.privs
	end

	modifier(snapshot)

	state.saved_privs[target] = snapshot

	spec_state = spec_state or spectator.get_spectator_state(target) or {}
	spec_state.match = spec_state.match or state.match_id
	spec_state.privs = snapshot
	spectator.set_spectator_state(target, spec_state)
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

local function install_priv_hooks()
	if priv_hooks_installed then
		return
	end

	priv_hooks_installed = true

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
end

function spectator.setup(context)
	state = context.state or error("spectator.setup requires state")
	timer = context.timer or error("spectator.setup requires timer module")
	rankings = context.rankings
	recent_rankings = context.recent_rankings
	bound_timer = 0

	install_priv_hooks()
end

function spectator.reset()
	bound_timer = 0
end

function spectator.on_globalstep(dtime)
	ensure_state()

	bound_timer = bound_timer + dtime
	if bound_timer < SPECTATOR_BOUND_CHECK_INTERVAL then
		return
	end

	bound_timer = bound_timer - SPECTATOR_BOUND_CHECK_INTERVAL
	for pname, eliminated in pairs(state.eliminated) do
		if eliminated then
			spectator.enforce_spectator_bounds(pname)
		end
	end
end

return spectator
