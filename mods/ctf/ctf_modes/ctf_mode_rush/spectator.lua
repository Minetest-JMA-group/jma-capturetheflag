local spectator = {}

-- Constants & storage
-- The spectator state lives in player metadata. The old modstorage key is only
-- read on join, to restore privileges saved before the metadata migration.
local LEGACY_SPEC_KEY = "ctf_mode_rush:spectator_state"
local legacy_storage = core.get_mod_storage()
local SPECTATOR_META_KEY = "ctf_mode_rush:is_spectator"
local SPECTATOR_STATE_META_KEY = "ctf_mode_rush:spectator_state"
local SPECTATOR_INFO_FORMNAME = "ctf_mode_rush:spectator_info"
local SPECTATOR_INFO_META_KEY = "ctf_mode_rush:hide_spectator_info"
local SPECTATOR_INFO_CHECKBOX = "ctf_mode_rush_spectator_hide"

-- Privileges are only ever touched through these helpers. Only the managed
-- privileges are snapshotted, modified and restored; everything else is left
-- alone.
local SPECTATOR_PRIVS = {
	fly = true,
	noclip = true,
}
-- Privileges back to these values when no snapshot is available
local DEFAULT_PRIVS = {
	fly = false,
	noclip = false,
}
-- Spectators only need the teleport item, so the hotbar is shrunk to one slot
local SPECTATOR_HOTBAR_SIZE = 1
local DEFAULT_HOTBAR_SIZE = 8
-- Runtime variables (filled by spectator.setup)
local state
local timer
local rankings
local recent_rankings

-- Forms & UI helpers
local function build_spectator_info_formspec(checked)
	local checkbox_label = core.formspec_escape("Don't show this again")
	local button_label = core.formspec_escape("Got it")
	local info_text = table.concat({
		"<style name=title color=#ffd166 size=20>",
		"<style name=body color=#ffffff size=14>",
		"<tag name=title><center>Rush Spectator Mode</center>",
		"<tag name=body>",
		"- Observe any player of the match and their surroundings.\n",
		"- Switch between players with the item.\n",
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
	core.after(0, function(name)
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
		local player = core.get_player_by_name(pname)
		if not player then return true end
		if fields[SPECTATOR_INFO_CHECKBOX] ~= nil then
			if fields[SPECTATOR_INFO_CHECKBOX] == "true" then
				player:get_meta():set_int(SPECTATOR_INFO_META_KEY, 1)
			else
				player:get_meta():set_int(SPECTATOR_INFO_META_KEY, 0)
			end
		end
		return true
	end)

-- Spectator state
function spectator.get_spectator_state(player)
	local raw = player:get_meta():get_string(SPECTATOR_STATE_META_KEY)
	if raw == "" then return end
	return core.deserialize(raw)
end
function spectator.set_spectator_state(player, data)
	local meta = player:get_meta()
	if not data then
		meta:set_string(SPECTATOR_STATE_META_KEY, "")
		return
	end
	meta:set_string(SPECTATOR_STATE_META_KEY, core.serialize(data))
end
local function set_spectator_flag(player, enabled)
	player:get_meta():set_int(SPECTATOR_META_KEY, enabled and 1 or 0)
end
local function has_spectator_flag(player)
	return player:get_meta():get_int(SPECTATOR_META_KEY) == 1
end

-- Privilege management
local function log_priv_state(name, context)
	core.log("action", string.format(
		"[ctf_mode_rush] %s: privs of %s: %s",
		context,
		name,
		core.privs_to_string(core.get_player_privs(name), ", ")
	))
end
-- Returns the managed privileges that differ from `target`, together with the
-- original values. `snapshot[priv] = true` means "the player had the priv",
-- `false` means "the player did not have it".
local function collect_priv_changes(privs, target)
	local changes, snapshot = {}, {}
	for priv, value in pairs(target) do
		local current = privs[priv] == true
		if current ~= value then
			changes[priv] = value
			snapshot[priv] = current
		end
	end
	return changes, snapshot
end
-- Applies `values` on top of the current privileges. Only keys present in
-- `values` are touched, so unmanaged privileges are preserved.
local function apply_priv_changes(name, values, context)
	if next(values) == nil then return end

	log_priv_state(name, context)
	local privs = core.get_player_privs(name)
	for priv, value in pairs(values) do
		if value then
			privs[priv] = true
		else
			privs[priv] = nil
		end
	end
	core.set_player_privs(name, privs)
end

-- Helper utilities
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

-- Picks the best living player out of a set of player names
local function select_best_anchor(pool)
	local best, best_score = nil, -math.huge
	for pname in pairs(pool) do
		local obj = core.get_player_by_name(pname)
		if obj and obj:get_hp() > 0 then
			local sc = get_player_score(pname)
			if sc > best_score then best_score, best = sc, pname end
		end
	end
	return best
end

-- Every living player of the match, regardless of the team
local function get_all_alive_players()
	local alive = {}
	for _, team_players in pairs(state.alive_players or {}) do
		for pname in pairs(team_players) do
			local obj = core.get_player_by_name(pname)
			if obj and obj:get_hp() > 0 then
				alive[pname] = true
			end
		end
	end
	return alive
end

-- Vanish handling
local function remove_attached(player, name)
	playertag.no_entity_attach[name] = true
	hpbar.no_entity_attach[name] = true
	server_cosmetics.no_entity_attach[name] = true
	wield3d.no_entity_attach[name] = true

	playertag.set(player, playertag.TYPE_NONE)
	hpbar.remove_hpbar(name)
	server_cosmetics.remove_entity_cosmetics(player)
	wield3d.remove_wielditem(player)
end

local function restore_attached(player, name)
	playertag.no_entity_attach[name] = nil
	hpbar.no_entity_attach[name] = nil
	server_cosmetics.no_entity_attach[name] = nil
	wield3d.no_entity_attach[name] = nil

	playertag.set(player, playertag.TYPE_ENTITY)
	hpbar.update_entity(player)
	server_cosmetics.update_entity_cosmetics(player,
		ctf_cosmetics.get_extra_clothing(player))
	wield3d.add_wielditem(player)
end

local function vanish(player)
	local player_name = player:get_player_name()

	remove_attached(player, player_name)
	local armor_groups = player:get_armor_groups()
	armor_groups.immortal = 1
	player:set_armor_groups(armor_groups)
	player:set_properties({
		visual_size = { x = 0, y = 0 },
		collisionbox = { 0, 0, 0, 0, 0, 0 },
		is_visible = false,
		pointable = false,
		makes_footstep_sound = false,
		show_on_minimap = false,
	})
end

local function unvanish(player)
	local player_name = player:get_player_name()

	restore_attached(player, player_name)
	local armor_groups = player:get_armor_groups()
	armor_groups.immortal = 0
	player:set_armor_groups(armor_groups)
	player:set_properties({
		is_visible = true,
		pointable = true,
		makes_footstep_sound = true,
		show_on_minimap = true,
	})

	player:set_nametag_attributes({
		text = player_name,
	})

	player_api.set_model(player, "character.b3d", true)
end

function spectator.disable_vanish(player)
	local name = player:get_player_name()
	player:hud_set_hotbar_itemcount(DEFAULT_HOTBAR_SIZE)
	if state.vanish_active[name] then
		unvanish(player)
		player:set_detach()
		player:set_camera({ mode = "first" })
	end
	state.vanish_active[name] = nil
end
local function apply_vanish(player)
	local name = player:get_player_name()
	if state.vanish_active[name] then return end
	vanish(player)
	state.vanish_active[name] = true
end

-- Team / privilege helpers
local function remove_player_from_team(name)
	ctf_teams.remove_online_player(name)
	ctf_teams.player_team[name] = nil
end
function spectator.restore_privs(player)
	local existing = spectator.get_spectator_state(player)
	if not existing and not has_spectator_flag(player) then return end

	local snapshot = existing and existing.privs or DEFAULT_PRIVS
	apply_priv_changes(player:get_player_name(), snapshot, "spectator restore")

	player:hud_set_hotbar_itemcount(DEFAULT_HOTBAR_SIZE)
	set_spectator_flag(player, false)
	spectator.set_spectator_state(player, nil)
end
local function spectator_set_inv(player)
	local inv = player:get_inventory()
	inv:set_list("main", {})
	inv:add_item("main", { name = "spectator_teleport:item", count = 1 })
	player:hud_set_hotbar_itemcount(SPECTATOR_HOTBAR_SIZE)
end

-- Core spectator creation
function spectator.make_spectator(player)
	local pname = player:get_player_name()
	local team = state.initial_team[pname]
	-- remove from alive players list
	if team and state.alive_players[team] then
		state.alive_players[team][pname] = nil
	end
	timer.update_round_huds()
	state.eliminated[pname] = true
	-- snapshot only the managed privileges that actually change
	local existing = spectator.get_spectator_state(player)
	local privs = core.get_player_privs(pname)
	local changes, snapshot = collect_priv_changes(privs, SPECTATOR_PRIVS)
	-- keep the original snapshot when the spectator state already exists
	if existing and existing.privs then
		snapshot = existing.privs
	end
	spectator.set_spectator_state(player, {
		match = state.match_id,
		privs = snapshot,
		team = state.initial_team[pname],
	})
	set_spectator_flag(player, true)
	apply_priv_changes(pname, changes, "spectator enter")
	remove_player_from_team(pname)
	player:set_detach()
	apply_vanish(player)
	spectator_set_inv(player)  -- Fixed typo
	-- attach to the best living player (spectators may watch any team)
	local best = select_best_anchor(get_all_alive_players())
	if best then
		local target = core.get_player_by_name(best)
		if target then
			player:set_attach(target, "", vector.zero())
			player:set_camera({ mode = "third" })

		end
	else
		hud_events.new(pname, {
			quick = true,
			text = "No player you can spectate right now.",
			color = "warning",
		})
	end
	player:set_hp(20)
	maybe_show_spectator_info(player)
end
function spectator.is_spectator(name)
	return state.eliminated[name] == true
end
function spectator.for_each_spectator(cb)
	for pname, elim in pairs(state.eliminated) do
		if elim then cb(pname) end
	end
end

-- Legacy modstorage compatibility: restores privileges saved by older
-- versions, which kept the whole privilege table in modstorage.
function spectator.restore_legacy_privs(player)
	local meta = player:get_meta()
	if meta:get_int(SPECTATOR_META_KEY) == 1 then return end
	if meta:get_string(SPECTATOR_STATE_META_KEY) ~= "" then return end

	local name = player:get_player_name()
	local key = LEGACY_SPEC_KEY .. ":" .. name
	local raw = legacy_storage:get_string(key)
	if raw == "" then return end

	legacy_storage:set_string(key, "")
	local legacy = core.deserialize(raw)
	if not legacy.privs then return end

	-- The saved table is the original privilege set, so the value of each
	-- managed privilege is taken from it and applied to the current set.
	local values = {}
	for priv in pairs(SPECTATOR_PRIVS) do
		values[priv] = legacy.privs[priv] == true
	end
	apply_priv_changes(name, values, "spectator legacy restore")
end

-- Public API
function spectator.setup(context)
	state = context.state or error("spectator.setup requires state")
	timer = context.timer or error("spectator.setup requires timer")
	rankings = context.rankings
	recent_rankings = context.recent_rankings
end

-- Detach spectators from anchor (when anchor leaves, e.g., joins elysium)
local function find_spectators_attached_to(anchor_name)
	local spectators = {}
	for pname, elim in pairs(state.eliminated) do
		if elim then
			local player = core.get_player_by_name(pname)
			if player then
				local parent = player:get_attach()
				if parent and parent:is_player() then
					---@cast parent PlayerRef
					local parent_name = parent:get_player_name()
					if parent_name == anchor_name then
						table.insert(spectators, pname)
					end
				end
			end
		end
	end
	return spectators
end

-- Detach all spectators from a specific anchor player
function spectator.detach_spectators_from(anchor_name)
	local spectators = find_spectators_attached_to(anchor_name)
	for _, pname in ipairs(spectators) do
		local player = core.get_player_by_name(pname)
		if player then
			player:set_detach()
		end
	end
	return spectators
end

function spectator.reassign_team_spectators(team)
	if not team then return end

	-- Spectators may watch any living player, not only their own team
	local pool = get_all_alive_players()
	if not next(pool) then return end

	-- Find all spectators that used to play for this team
	local team_spectators = {}
	for pname, elim in pairs(state.eliminated) do
		if elim and state.initial_team[pname] == team then
			table.insert(team_spectators, pname)
		end
	end

	if #team_spectators == 0 then return end

	-- Choose an anchor for each spectator.
	for _, pname in ipairs(team_spectators) do
		local player = core.get_player_by_name(pname)
		if player then
			local new_anchor = select_best_anchor(pool)
			local target = new_anchor and core.get_player_by_name(new_anchor)
			player:set_detach()
			if target then
				player:set_attach(target, "", { x = 0, y = 1.5, z = 0 })
				player:set_camera({mode = "third"})

				local anchor_team = ctf_teams.get(new_anchor)
				hud_events.new(pname, {
					quick = true,
					text = anchor_team
						and string.format("Reassigned to spectate %s (%s)", new_anchor, anchor_team)
						or ("Reassigned to spectate " .. new_anchor),
					color = "info",
				})
			else
				hud_events.new(pname, {
					quick = true,
					text = "No player you can spectate right now.",
					color = "warning",
				})
			end
		end
	end
end

return spectator
