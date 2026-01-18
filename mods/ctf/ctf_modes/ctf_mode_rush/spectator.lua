-------------------------------------------------------------------------------
--  CTF‑Mode Rush – Spectator module (fixed)
--------------------------------------------------------------------------------

local spectator = {}

-- ----------------------------------------------------------------------
--  Constants & storage
-- ----------------------------------------------------------------------
local RUSH_SPEC_KEY = "ctf_mode_rush:spectator_state"
local storage       = core.get_mod_storage()

local SPECTATOR_INFO_FORMNAME   = "ctf_mode_rush:spectator_info"
local SPECTATOR_INFO_META_KEY   = "ctf_mode_rush:hide_spectator_info"
local SPECTATOR_INFO_CHECKBOX   = "ctf_mode_rush_spectator_hide"
local SPECTATOR_INFO_SHOW_DELAY = 0

local function storage_key(name)
	if type(name) ~= "string" or name == "" then return end
	return RUSH_SPEC_KEY .. ":" .. name
end

local SPECTATOR_CHAT_COLOR = "#8f7bb9"

-- ----------------------------------------------------------------------
--  Runtime variables (filled by spectator.setup)
-- ----------------------------------------------------------------------
local state
local timer
local rankings
local recent_rankings
local bound_timer = 0
local priv_hooks_installed = false

local function ensure_state()
	if not state then error("spectator not initialised") end
end

local function safe_deserialize(data)
	if data == "" then return end
	local ok, val = pcall(core.deserialize, data)
	if ok then return val end
end

--------------------------------------------------------------------------------
--  Forms & UI helpers
--------------------------------------------------------------------------------
local function build_spectator_info_formspec(checked)
	local checkbox_label = core.formspec_escape("Don't show this again")
	local button_label   = core.formspec_escape("Got it")
	local info_text = table.concat({
		"<style name=title color=#ffd166 size=20>",
		"<style name=body color=#ffffff size=14>",
		"<tag name=title><center>Rush Spectator Mode</center>",
		"<tag name=body>",
		"- Observe teammates and their surroundings.\n",
		"- Switch between teammates with the item.\n",
		"- Warn teammates about enemies.\n",
		"- Constant communication saves lives!",
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
		if core.get_player_by_name(name) then
			core.show_formspec(name, SPECTATOR_INFO_FORMNAME,
			                   build_spectator_info_formspec(false))
		end
	end, pname)
end

local function maybe_show_spectator_info(player)
	if player:get_meta():get_int(SPECTATOR_INFO_META_KEY) == 1 then return end
	show_spectator_info(player)
end

ctf_core.register_on_formspec_input("^" .. SPECTATOR_INFO_FORMNAME .. "$",
	function(pname, formname, fields)
		if formname ~= SPECTATOR_INFO_FORMNAME then return end
		local player = PlayerObj(pname)
		if not player then return true end
		if fields[SPECTATOR_INFO_CHECKBOX] == "true" then
			player:get_meta():set_int(SPECTATOR_INFO_META_KEY, 1)
		else
			player:get_meta():set_int(SPECTATOR_INFO_META_KEY, 0)
		end
		return true
	end)

--------------------------------------------------------------------------------
--  Spectator state persistence
--------------------------------------------------------------------------------
function spectator.get_spectator_state(name)
	local key = storage_key(name)
	if not key then return end
	local raw = storage:get_string(key)
	if raw == "" then return end
	local parsed = safe_deserialize(raw)
	if type(parsed) ~= "table" then return end
	parsed.privs = type(parsed.privs) == "table" and parsed.privs or {}
	parsed.team  = type(parsed.team) == "string" and parsed.team ~= "" and parsed.team or nil
	return parsed
end

function spectator.set_spectator_state(name, data)
	local key = storage_key(name)
	if not key then return end
	if not data or (not data.match and (not data.privs or next(data.privs) == nil)) then
		storage:set_string(key, "")
		return
	end
	local payload = { match = data.match, privs = data.privs }
	if type(data.team) == "string" and data.team ~= "" then payload.team = data.team end
	storage:set_string(key, core.serialize(payload))
end

--------------------------------------------------------------------------------
--  Helper utilities
--------------------------------------------------------------------------------
local function get_player_score(pname)
	if recent_rankings then
		local rec = recent_rankings.get(pname)
		if rec and rec.score then return rec.score end
	end
	if rankings then
		local overall = rankings:get(pname)
		if overall and overall.score then return overall.score end
	end
	return 0
end

local function select_anchor_for_team(team)
	local alive = state.alive_players[team]
	if not alive then return nil end
	local best, best_score = nil, -math.huge
	for pname in pairs(alive) do
		local obj = core.get_player_by_name(pname)
		if obj and obj:get_hp() > 0 then
			local sc = get_player_score(pname)
			if sc > best_score then best_score, best = sc, pname end
		end
	end
	return best
end

local function place_spectator_near_anchor(player)
	local pname = player:get_player_name()
	local anchor_name = state.spectator_anchor[pname]
	if not anchor_name then return end
	local anchor = core.get_player_by_name(anchor_name)
	if not anchor then return end
	local pos = anchor:get_pos()
	if not pos then return end
	local offset = {
		x = math.random(-3, 3),
		y = MIN_SPECTATOR_ALTITUDE + 2,
		z = math.random(-3, 3),
	}
	player:set_pos(vector.add(pos, offset))
end

--------------------------------------------------------------------------------
--  Vanish handling
--------------------------------------------------------------------------------
function spectator.disable_vanish(player)
	ensure_state()
	local name = player:get_player_name()
	if state.vanish_active[name] then vanish.off(player) end
	state.vanish_active[name] = nil
end

local function apply_vanish(player)
	local name = player:get_player_name()
	if state.vanish_active[name] then return end
	vanish.on(player, { pointable = false, is_visible = false })
	state.vanish_active[name] = true
end

--------------------------------------------------------------------------------
--  Team / privilege helpers
--------------------------------------------------------------------------------
local function remove_player_from_team(name)
	ctf_teams.remove_online_player(name)
	ctf_teams.player_team[name] = nil
	ctf_teams.non_team_players[name] = true
end

function spectator.restore_privs(name)
	ensure_state()
	local privs = state.saved_privs[name]
	if not privs then
		local ss = spectator.get_spectator_state(name)
		if ss then privs = ss.privs end
	end
	if not privs then privs = core.get_player_privs(name) end
	core.set_player_privs(name, privs)
	state.saved_privs[name] = nil
	spectator.set_spectator_state(name, nil)
end

local function specatator_set_inv(player)
	local inv = player:get_inventory()
	inv:set_list("main", {})
	inv:add_item("main", { name = "spectator_teleport:item", count = 1 })
end

--------------------------------------------------------------------------------
--  Core spectator creation
--------------------------------------------------------------------------------
function spectator.make_spectator(player)
	ensure_state()
	local pname = player:get_player_name()
	local team  = state.initial_team[pname]

	-- remove from alive list
	if team and state.alive_players[team] then state.alive_players[team][pname] = nil end
	timer.update_round_huds()
	state.eliminated[pname] = true

	-- store original privs once
	if not state.saved_privs[pname] then
		state.saved_privs[pname] = core.get_player_privs(pname)
	end

	-- give spectator privs
	local privs = table.copy(state.saved_privs[pname])
	privs.interact = true
	privs.fast     = nil
	privs.fly      = true
	privs.noclip   = true
	core.set_player_privs(pname, privs)

	remove_player_from_team(pname)
	apply_vanish(player)
	specatator_set_inv(player)

	-- attach to best teammate
	local best = select_anchor_for_team(team)
	if best then
		local target = core.get_player_by_name(best)
		if target then
			player:set_detach()
			player:set_attach(target, "", {x = 0, y = 0, z = 0},
			                     {x = 0, y = 0, z = 0})
			player:set_pos(target:get_pos())
			if player.set_camera then
				player:set_camera({mode = "third"})
			end
		end
	else
		hud_events.new(pname, {
			quick = true,
			text  = "No teammate found!",
			color = "warning",
		})
	end

	player:set_hp(20)
	maybe_show_spectator_info(player)

	-- persist state (includes current match ID)
	spectator.set_spectator_state(pname, {
		match = state.match_id,
		privs = state.saved_privs[pname],
		team  = state.initial_team[pname],
	})
end

function spectator.is_spectator(name)
	ensure_state()
	return state.eliminated[name] == true
end

function spectator.for_each_spectator(cb)
	ensure_state()
	for pname, elim in pairs(state.eliminated) do
		if elim then cb(pname) end
	end
end

--------------------------------------------------------------------------------
--  Privilege change tracking
--------------------------------------------------------------------------------
local function trim(s) return (s:gsub("^%s+", ""):gsub("%s+$", "")) end

local function update_saved_priv_snapshot(target, modifier)
	if not state.saved_privs then return end
	local snap = state.saved_privs[target]
	local spec_state

	if not snap then
		spec_state = spectator.get_spectator_state(target)
		if not spec_state or not spec_state.match then return end
		snap = spec_state.privs
	end

	modifier(snap)
	state.saved_privs[target] = snap

	spec_state = spec_state or spectator.get_spectator_state(target) or {}
	spec_state.match = spec_state.match or state.match_id
	spec_state.privs = snap
	spectator.set_spectator_state(target, spec_state)
end

local function parse_priv_param(param)
	if not param then return end
	local target, payload = param:match("^(%S+)%s+(.+)$")
	if not target then return end
	payload = trim(payload)
	if payload == "" then return end
	if payload == "all" then return target, "all" end
	local list = {}
	for tok in payload:gmatch("[^,]+") do
		local p = trim(tok)
		if p ~= "" then table.insert(list, p) end
	end
	if #list == 0 then return end
	return target, list
end

local function parse_self_priv_param(param)
	if not param then return end
	param = trim(param)
	if param == "" then return end
	local list = {}
	for tok in param:gmatch("[^,]+") do
		local p = trim(tok)
		if p ~= "" then table.insert(list, p) end
	end
	if #list == 0 then return end
	return list
end

local function record_priv_change(target, privs, grant)
	if not privs then return end
	update_saved_priv_snapshot(target, function(snap)
		if privs == "all" then
			for name in pairs(core.registered_privileges) do
				snap[name] = grant and true or nil
			end
		else
			for _, p in ipairs(privs) do
				snap[p] = grant and true or nil
			end
		end
	end)
end

local function create_priv_wrapper(is_grant, resolver)
	return function(orig)
		return function(name, param)
			local ok, msg = orig(name, param)
			if ok then
				local tgt, privs = resolver(name, param)
				if tgt and privs then record_priv_change(tgt, privs, is_grant) end
			end
			return ok, msg
		end
	end
end

local function install_priv_hooks()
	if priv_hooks_installed then return end
	priv_hooks_installed = true

	core.after(0, function()
		local grant_wrapper   = create_priv_wrapper(true,
		                                          function(_, p) return parse_priv_param(p) end)
		local revoke_wrapper  = create_priv_wrapper(false,
		                                          function(_, p) return parse_priv_param(p) end)
		local grantme_wrapper = create_priv_wrapper(true,
		                                          function(exec, p) return exec, parse_self_priv_param(p) end)
		local revokeme_wrapper = create_priv_wrapper(false,
		                                           function(exec, p) return exec, parse_self_priv_param(p) end)

		-- wrap built‑in chat commands
		if core.registered_chatcommands.grant then
			core.registered_chatcommands.grant.func =
				grant_wrapper(core.registered_chatcommands.grant.func)
		end
		if core.registered_chatcommands.revoke then
			core.registered_chatcommands.revoke.func =
				revoke_wrapper(core.registered_chatcommands.revoke.func)
		end
		if core.registered_chatcommands.grantme then
			core.registered_chatcommands.grantme.func =
				grantme_wrapper(core.registered_chatcommands.grantme.func)
		end
		if core.registered_chatcommands.revokeme then
			core.registered_chatcommands.revokeme.func =
				revokeme_wrapper(core.registered_chatcommands.revokeme.func)
		end

		-- also wrap future registrations
		local old_reg = core.register_chatcommand
		function core.register_chatcommand(name, def)
			if name == "grant" and def.func then def.func = grant_wrapper(def.func) end
			if name == "revoke" and def.func then def.func = revoke_wrapper(def.func) end
			if name == "grantme" and def.func then def.func = grantme_wrapper(def.func) end
			if name == "revokeme" and def.func then def.func = revokeme_wrapper(def.func) end
			return old_reg(name, def)
		end

		local old_ovr = core.override_chatcommand
		function core.override_chatcommand(name, def)
			if name == "grant" and def.func then def.func = grant_wrapper(def.func) end
			if name == "revoke" and def.func then def.func = revoke_wrapper(def.func) end
			if name == "grantme" and def.func then def.func = grantme_wrapper(def.func) end
			if name == "revokeme" and def.func then def.func = revokeme_wrapper(def.func) end
			return old_ovr(name, def)
		end
	end)
end

--------------------------------------------------------------------------------
--  Public API
--------------------------------------------------------------------------------
function spectator.setup(context)
	state               = context.state or error("spectator.setup requires state")
	timer               = context.timer or error("spectator.setup requires timer")
	rankings            = context.rankings
	recent_rankings     = context.recent_rankings
	bound_timer         = 0
	install_priv_hooks()
end

function spectator.reset()
	bound_timer = 0
end

function spectator.on_globalstep(dtime) end

--------------------------------------------------------------------------------
--  Missing function – now defined (no‑op)
--------------------------------------------------------------------------------
function spectator.reassign_team_spectators(team)
	-- Placeholder: currently we don’t need extra work when a team is rebuilt.
	-- If you later want to move spectators to a new anchor, put that logic here.
end

--------------------------------------------------------------------------------
--  Re‑join handling (persist spectator across disconnects)
--------------------------------------------------------------------------------
minetest.register_on_joinplayer(function(player)
	local pname = player:get_player_name()
	local ss = spectator.get_spectator_state(pname)
	if ss and ss.match == state.match_id then
		-- Restore privileges first
		if pname.set_camera then
			pname:set_camera({mode = "any"})
		core.set_player_privs(pname, ss.privs)
		-- Turn player back into a spectator
		spectator.make_spectator(player)
		hud_events.new(pname, {
			quick = true,
			text  = "Rejoined as spectator",
			color = "info",
		})
	end
end)

--------------------------------------------------------------------------------
--  End‑of‑round scoring (fair 500‑point split)
--------------------------------------------------------------------------------
function spectator.distribute_survivor_score()
	ensure_state()
	-- Gather all alive players
	local survivors = {}
	for _, alive_tbl in pairs(state.alive_players) do
		for pname in pairs(alive_tbl) do survivors[#survivors + 1] = pname end
	end
	if #survivors == 0 then return end

	local per_player = math.floor(500 / #survivors)
	for _, pname in ipairs(survivors) do
		-- Adjust this call to match your ranking system’s API
		if rankings and rankings.add_score then
			rankings:add_score(pname, per_player)
		end
	end
end

return spectator
