local spectator = {}

local RUSH_SPEC_KEY = "ctf_mode_rush:spectator_state"
local storage = core.get_mod_storage()

local SPECTATOR_INFO_FORMNAME = "ctf_mode_rush:spectator_info"
local SPECTATOR_INFO_META_KEY = "ctf_mode_rush:hide_spectator_info"
local SPECTATOR_INFO_CHECKBOX = "ctf_mode_rush_spectator_hide"
local SPECTATOR_INFO_SHOW_DELAY = 0

local function storage_key(name)
	if type(name) ~= "string" or name == "" then
		return
	end
	return RUSH_SPEC_KEY .. ":" .. name
end

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

	local ok, value = pcall(core.deserialize, data)
	if ok then
		return value
	end
end

local function build_spectator_info_formspec(checked)
	local checkbox_label = core.formspec_escape("Don't show this again")
	local button_label = core.formspec_escape("Got it")

	local info_text = table.concat({
		"<style name=title color=#ffd166 size=20>",
		"<style name=body color=#ffffff size=14>",
		"<tag name=title><center>Rush Spectator Mode</center></tag>",
		"<tag name=body>",
		"- You are now following your teammates in third person view and can help by watching their surroundings.\n",
		"- You are invisible and cannot interact, so focus on scouting and sharing intel in team chat.",
		"</tag>",
	}, "\n")

	return table.concat({
		"formspec_version[4]",
		"size[11,6.2]",
		string.format(
			"checkbox[7.2,0.3;%s;%s;%s]",
			SPECTATOR_INFO_CHECKBOX,
			checkbox_label,
			checked and "true" or "false"
		),
		string.format("hypertext[0.4,0.9;10.2,4.2;info;%s]", info_text),
		string.format("button_exit[4.4,5.4;2.2,0.8;spectator_info_ok;%s]", button_label),
	})
end

local function show_spectator_info(player)
	local pname = player:get_player_name()
	core.after(SPECTATOR_INFO_SHOW_DELAY, function(name)
		local target = core.get_player_by_name(name)
		if not target then
			return
		end

		core.show_formspec(name, SPECTATOR_INFO_FORMNAME, build_spectator_info_formspec(false))
	end, pname)
end

local function maybe_show_spectator_info(player)
	local meta = player:get_meta()
	if meta:get_int(SPECTATOR_INFO_META_KEY) == 1 then
		return
	end

	show_spectator_info(player)
end

ctf_core.register_on_formspec_input("^" .. SPECTATOR_INFO_FORMNAME .. "$", function(pname, formname, fields)
	if formname ~= SPECTATOR_INFO_FORMNAME then
		return
	end

	local player = PlayerObj(pname)
	if not player then
		return true
	end

	local hide_pref = fields[SPECTATOR_INFO_CHECKBOX]
	if hide_pref == "true" then
		player:get_meta():set_int(SPECTATOR_INFO_META_KEY, 1)
	elseif hide_pref == "false" then
		player:get_meta():set_int(SPECTATOR_INFO_META_KEY, 0)
	end

	return true
end)

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

	if type(parsed.team) ~= "string" or parsed.team == "" then
		parsed.team = nil
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

	if type(data.team) == "string" and data.team ~= "" then
		payload.team = data.team
	end

	storage:set_string(key, core.serialize(payload))
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
		local player_obj = core.get_player_by_name(pname)
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

	local anchor = core.get_player_by_name(anchor_name)
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

function spectator.reassign_team_spectators(team)
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
		privs = core.get_player_privs(name)
	end

	core.set_player_privs(name, privs)
	state.saved_privs[name] = nil
	spectator.set_spectator_state(name, nil)
end

function specatator_set_inv(player)
	local inv = player:get_inventory()
	inv:set_list("main", {})

	inv:add_item("main", {name = "spectator_teleport:item", count = 1})
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
		state.saved_privs[pname] = core.get_player_privs(pname)
	end
	local privs = table.copy(state.saved_privs[pname])
	privs.interact = nil
	privs.fast = nil
	privs.fly = true
	privs.noclip = true
	core.set_player_privs(pname, privs)
	remove_player_from_team(pname)
	apply_vanish(player)

	specatator_set_inv(player)

	local best_player = select_anchor_for_team(team)
	if best_player then
		local target = core.get_player_by_name(best_player)
		if target then
			player:set_detach()
			player:set_attach(target, "", {x=0, y=0, z=0}, {x=0, y=0, z=0})
			player:set_pos(target:get_pos())

			if player.set_camera then
				player:set_camera({mode = "third"})
			else
				return nil
			end
		end
	else
		hud_events.new(pname, {
			quick = true,
			text = "No teammate found!",
			color = "warning",
		})
	end

	player:set_hp(20)
	maybe_show_spectator_info(player)
	spectator.set_spectator_state(pname, {
		match = state.match_id,
		privs = state.saved_privs[pname],
		team = state.initial_team[pname],
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
			for name in pairs(core.registered_privileges) do
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

	core.after(0, function()
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

		local grant_def = core.registered_chatcommands.grant
		if grant_def and type(grant_def.func) == "function" then
			grant_def.func = grant_wrapper(grant_def.func)
		end

		local revoke_def = core.registered_chatcommands.revoke
		if revoke_def and type(revoke_def.func) == "function" then
			revoke_def.func = revoke_wrapper(revoke_def.func)
		end

		local grantme_def = core.registered_chatcommands.grantme
		if grantme_def and type(grantme_def.func) == "function" then
			grantme_def.func = grantme_wrapper(grantme_def.func)
		end

		local revokeme_def = core.registered_chatcommands.revokeme
		if revokeme_def and type(revokeme_def.func) == "function" then
			revokeme_def.func = revokeme_wrapper(revokeme_def.func)
		end

		local old_register_chatcommand = core.register_chatcommand
		function core.register_chatcommand(name, def)
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

		local old_override_chatcommand = core.override_chatcommand
		function core.override_chatcommand(name, def)
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
end

return spectator
