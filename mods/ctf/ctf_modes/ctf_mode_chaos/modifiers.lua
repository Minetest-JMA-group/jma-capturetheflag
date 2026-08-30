local weapons = {}
local default_weapon

-- Per player, per weapon upgrade state:
--   upgrades[pname][weapon_id] = { modes = {}, params = {} }
local upgrades = {}

-- Per player, per weapon selected mode:
--   current_mode[pname][weapon_id] = mode key
local current_mode = {}

local last_wielded_weapon = {}

local active_global = {}

local short_names = {
	frag = "Frag",
	bouncy = "Bouncy",
	cluster = "Cluster",
	sticky = "Sticky",
	shotgun = "Shotgun",
	rocket = "Rocket",
	rain = "Rain",
}

local hud = mhud.init()
local HUD_NAME = "ctf_mode_chaos:upgrades"

local hud_colors = {
	gold = core.get_color_escape_sequence("#FFD700"),
	cyan = core.get_color_escape_sequence("#00EEFF"),
	gray = core.get_color_escape_sequence("#9A9A9A"),
	green = core.get_color_escape_sequence("#7CFC00"),
	white = core.get_color_escape_sequence("#FFFFFF"),
}

local UPDATE_INTERVAL = 0.2

local function get_upgrades(player, weapon_id)
	local pname = PlayerName(player)
	if not pname then
		return { modes = {}, params = {} }
	end
	local p = upgrades[pname]
	return (p and p[weapon_id]) or { modes = {}, params = {} }
end

local function set_upgrades(player, weapon_id, u)
	local pname = PlayerName(player)
	if not pname then
		return
	end
	if not upgrades[pname] then
		upgrades[pname] = {}
	end
	upgrades[pname][weapon_id] = u
end

-- Returns true when the player is holding or owns any item of the weapon.
local function player_owns_weapon(def, user)
	if def.is_weapon_item and def.is_weapon_item(user:get_wielded_item():get_name()) then
		return true
	end
	local inv = user:get_inventory()
	for i = 1, inv:get_size("main") do
		if def.is_weapon_item(inv:get_stack("main", i):get_name()) then
			return true
		end
	end
	return false
end

-- Item name of a mode/param mod. Shared mods (info.shared) are a single item
-- named after the modifier key (e.g. ctf_mode_chaos:fast_reload) that works on
-- every weapon listing them; weapon specific mods embed the weapon's item
-- prefix (e.g. ctf_mode_chaos:mod_bouncy) and only work on that weapon.
local function mod_item_name(def, key, info)
	if info.shared then
		return "ctf_mode_chaos:" .. key
	end
	return def.item_prefix .. "_" .. key
end

-- Shared mod keys whose single item has already been registered.
local registered_shared = {}

-- Returns a weapon id + mod kind ("mode"|"param") when the shared mod `key`
-- applies to `def` and the player can still install it (owns the weapon and
-- has not maxed it out), otherwise nil.
local function shared_target(user, key, weapon_id, def)
	local info = def.mode_mods[key]
	local kind = "mode"
	if not info then
		info = def.param_defs[key]
		kind = "param"
	end
	if not info then
		return nil
	end
	if kind == "mode" then
		if ctf_mode_chaos.has_mode(user, weapon_id, key) then
			return nil
		end
	elseif ctf_mode_chaos.param_level(user, weapon_id, key) >= info.max_level then
		return nil
	end
	if not player_owns_weapon(def, user) then
		return nil
	end
	return weapon_id, kind
end

-- Weapons a player could install the shared mod `key` on, sorted by name.
local function get_shared_targets(user, key)
	local targets = {}
	for weapon_id, def in pairs(weapons) do
		local wid, kind = shared_target(user, key, weapon_id, def)
		if wid then
			table.insert(targets, { id = wid, def = def, kind = kind })
		end
	end
	table.sort(targets, function(a, b)
		return a.def.description < b.def.description
	end)
	return targets
end

local function show_shared_picker(user, key, info)
	local pname = PlayerName(user)
	if not pname then
		return
	end

	local targets = get_shared_targets(user, key)
	if #targets == 0 then
		hud_events.new(pname, {
			text = "You have no weapon to install " .. info.description .. " on!",
			quick = true,
		})
		return
	end

	local form = "size[6," .. (1.6 + #targets * 0.9) .. "]"
		.. "label[0,0;Choose a weapon to install "
		.. core.formspec_escape(info.description) .. " on:]"
	local y = 0.7
	for _, target in ipairs(targets) do
		form = form .. string.format(
			"button_exit[0.5,%f;5,0.8;weapon_%s;%s]",
			y,
			target.id,
			core.formspec_escape(target.def.description)
		)
		y = y + 0.9
	end
	form = form .. string.format("button_exit[0.5,%f;5,0.8;cancel;Cancel]", y)

	core.show_formspec(pname, "ctf_mode_chaos:shared_mod_" .. key, form)
end

-- Registers the single item of a shared modifier (only once, even when several
-- weapons list the same shared modifier key).
local function register_shared_mod(key, info)
	if registered_shared[key] then
		return
	end
	registered_shared[key] = true

	local description = "Weapon Mod: " .. info.description
		.. "\nUse it to choose a weapon to install it on"
	if info.max_level then
		description = description .. "\nStackable up to level " .. info.max_level
	end

	core.register_craftitem("ctf_mode_chaos:" .. key, {
		description = description,
		inventory_image = info.icon,
		stack_max = 1,
		groups = {},
		on_use = function(itemstack, user, pointed_thing)
			if not user or not user:is_player() then
				return
			end
			---@cast user PlayerRef
			show_shared_picker(user, key, info)
			return itemstack
		end,
	})
end

-- Shared mod items: the weapon buttons of the picker formspec are handled
-- here. The form name embeds the mod key (ctf_mode_chaos:shared_mod_<key>).
core.register_on_player_receive_fields(function(player, formname, fields)
	local prefix = "ctf_mode_chaos:shared_mod_"
	if formname:sub(1, #prefix) ~= prefix then
		return
	end
	local key = formname:sub(#prefix + 1)
	local pname = PlayerName(player)
	if not pname then
		return
	end

	for weapon_id, def in pairs(weapons) do
		if fields["weapon_" .. weapon_id] then
			local info = def.mode_mods[key]
			local kind = "mode"
			if not info then
				info = def.param_defs[key]
				kind = "param"
			end
			if not info then
				return
			end

			local inv = player:get_inventory()
			if not inv:contains_item("main", mod_item_name(def, key, info) .. " 1") then
				hud_events.new(pname, {
					text = "You no longer have this mod!",
					quick = true,
				})
				return
			end

			local ok, message = ctf_mode_chaos.apply_mod(player, kind, key, weapon_id)
			if ok then
				inv:remove_item("main", mod_item_name(def, key, info) .. " 1")
				ctf_mode_chaos.update_hud(player)
			end
			hud_events.new(pname, {
				text = message,
				quick = true,
			})
			return
		end
	end
end)

-- Registers the modifier craft items of a weapon. Each mod item is bound to
-- exactly one weapon; the item name embeds the weapon id so drop pools and
-- inventories can tell them apart. Shared modifiers (info.shared) are the
-- exception: they are registered once and can be installed on any weapon
-- listing them.
local function register_mod_items(def)

	local function handle_mod(itemstack, user, kind, key)
		if not user or not user:is_player() then
			return
		end
		---@cast user PlayerRef
		local pname = PlayerName(user)
		if not player_owns_weapon(def, user) then
			hud_events.new(pname, {
				text = "You need the " .. def.description .. " to install this mod!",
				quick = true,
			})
			return
		end
		local ok, message = ctf_mode_chaos.apply_mod(user, kind, key, def.id)
		if ok then
			itemstack:take_item(1)
			ctf_mode_chaos.update_hud(user)
		end
		hud_events.new(pname, {
			text = message,
			quick = true,
		})
	end

	for mode, info in pairs(def.mode_mods) do
		if info.shared then
			register_shared_mod(mode, info)
		else
			core.register_craftitem(def.item_prefix .. "_" .. mode, {
				description = "Weapon Mod: " .. info.description
					.. "\nUnlocks a new mode for " .. def.description
					.. "\nUse while holding it to install",
				inventory_image = info.icon,
				stack_max = 1,
				groups = {},
				on_use = function(itemstack, user, pointed_thing)
					handle_mod(itemstack, user, "mode", mode)
					return itemstack
				end,
			})
		end
	end

	for param, info in pairs(def.param_defs) do
		if info.shared then
			register_shared_mod(param, info)
		else
			core.register_craftitem(def.item_prefix .. "_" .. param, {
				description = "Weapon Mod: " .. info.description
					.. "\nFor: " .. def.description
					.. "\nStackable up to level " .. info.max_level
					.. "\nUse while holding it to install",
				inventory_image = info.icon,
				stack_max = 1,
				groups = {},
				on_use = function(itemstack, user, pointed_thing)
					handle_mod(itemstack, user, "param", param)
					return itemstack
				end,
			})
		end
	end
end

-- Registers a weapon so it can receive modifiers. Each weapon gets its own
-- per player upgrade state (unlocked modes + param levels) and current mode.
--
-- def fields:
--   id             unique weapon id
--   description    display name, e.g. "Grenade Launcher"
--   mode_order     ordered list of mode keys; the first entry is the base
--                  mode that is always unlocked
--   base_mode      optional, defaults to mode_order[1]
--   param_defs     { [param] = { description, max_level, weight, icon,
--                  shared } }
--   mode_mods      { [mode] = { description, weight, icon, shared } }
--                  Mods with shared = true are registered once under the key
--                  itself (e.g. ctf_mode_chaos:fast_reload) instead of the
--                  weapon's prefix, and are installable on every weapon
--                  listing them via a weapon-picker formspec.
--   item_prefix    item name prefix of this weapon's per-weapon mod items,
--                  e.g. "ctf_mode_chaos:mod" -> "ctf_mode_chaos:mod_bouncy"
--   item           optional item string of single-item weapons (bunny sword,
--                  shield, stamina booster), e.g. "ctf_mode_chaos:bunny_sword"
--   tool_prefix    optional item name prefix of the weapon's per-mode tools,
--                  e.g. "ctf_mode_chaos:grenade_launcher_" -> per-mode items
--                  like "ctf_mode_chaos:grenade_launcher_frag". Auto-derived
--                  from the weapon API for the launchers
--   is_weapon_item function(itemname) -> bool; matches the weapon's items so
--                  the engine can detect the currently wielded weapon
--   short_names    optional { [mode] = "HUD label" } overrides
--   on_respawn     optional function(player, weapon_id) called when a player respawns
--   on_wield       optional function(player, weapon_id) called when the player
--                  starts holding the weapon; apply modifier effects here
--   on_unwield     optional function(player, weapon_id) called when the player
--                  stops holding the weapon; roll effects back to default here
--   on_global      optional function(player, weapon_id, count) called while
--                  weapon items are in the hotbar (main slots 1-8). `count`
--                  is the number of items in the hotbar (stacked boosters
--                  count), so effects can scale with it. It returns the HUD
--                  label shown while the effect is active (or nil for none),
--                  so the label can depend on the player's upgrade state.
--                  Roll the old effect back with on_global_clear first if the
--                  count changes. It is re-called right after an upgrade is
--                  applied or removed while the item is still in the hotbar,
--                  so effects can react to changed param levels.
--   on_global_clear optional function(player, weapon_id) called when the item
--                  is no longer in the hotbar; roll the effect back here
function ctf_mode_chaos.register_weapon_template(def)
	if not def or not def.id then
		error("ctf_mode_chaos: register_weapon_template() requires an 'id'")
	end
	if weapons[def.id] then
		error("ctf_mode_chaos: weapon '" .. def.id .. "' is already registered")
	end
	def.mode_order = def.mode_order or {}
	def.param_defs = def.param_defs or {}
	def.mode_mods = def.mode_mods or {}
	def.base_mode = def.base_mode or def.mode_order[1]
	if not def.base_mode then
		error("ctf_mode_chaos: weapon '" .. def.id
			.. "' needs a base_mode or a non-empty mode_order")
	end
	def.item_prefix = def.item_prefix or "ctf_mode_chaos:mod_" .. def.id

	-- Tool items: single-item weapons provide `item`; the multi-mode launchers
	-- get their tool prefix auto-derived from the weapon API, giving one item
	-- per mode: "<tool_prefix><mode>".
	if not def.tool_prefix and ctf_mode_chaos.weapons_api
			and ctf_mode_chaos.weapons_api.tool_prefixes then
		def.tool_prefix = ctf_mode_chaos.weapons_api.tool_prefixes[def.id]
	end

	weapons[def.id] = def
	default_weapon = default_weapon or def.id
	register_mod_items(def)
	return def.id
end

-- Returns a registered weapon definition, or nil.
function ctf_mode_chaos.get_weapon(weapon_id)
	return weapons[weapon_id]
end

-- Returns the id of the default weapon (the first one registered).
function ctf_mode_chaos.get_default_weapon()
	return default_weapon
end

-- Returns the item string of a weapon's tool item, read from its definition.
-- Accepts a registered weapon id or a weapon definition table. Single-item
-- weapons (bunny sword, shield, stamina booster) return their `item`; the
-- multi-mode launchers return "<tool_prefix><mode>", defaulting to the base
-- mode, e.g. "ctf_mode_chaos:grenade_launcher_frag". Returns nil for unknown
-- weapons or when the definition carries no item info.
function ctf_mode_chaos.get_weapon_item(weapon, mode)
	local def = weapon
	if type(weapon) == "string" then
		def = weapons[weapon]
	elseif not weapon then
		def = weapons[default_weapon]
	end
	if not def or not def.id then
		return nil
	end
	if def.item then
		return def.item
	end
	mode = mode or def.base_mode
	if def.tool_prefix and mode then
		return def.tool_prefix .. mode
	end
	return nil
end

-- Returns the weapon the player is currently holding, or nil.
function ctf_mode_chaos.get_wielded_weapon(player)
	local wielded = player:get_wielded_item():get_name()
	for weapon_id, def in pairs(weapons) do
		if def.is_weapon_item and def.is_weapon_item(wielded) then
			return weapon_id
		end
	end
	return nil
end

-- Calls the on_respawn callback of the relevant weapon: the currently wielded
-- weapon, falling back to the default weapon. Returns the weapon id handled.
function ctf_mode_chaos.on_respawn(player)
	local weapon_id = ctf_mode_chaos.get_wielded_weapon(player) or default_weapon
	local def = weapons[weapon_id]
	if def and def.on_respawn then
		def.on_respawn(player, weapon_id)
	end

	ctf_mode_chaos.update_hud(player)
	return weapon_id
end

-- Called when the player's wielded item changes: rolls back the modifier
-- effects of the previously held weapon (on_unwield) and applies the effects
-- of the newly held one (on_wield). No-op if the weapon did not change.
function ctf_mode_chaos.on_weapon_switch(player, old_weapon, new_weapon)
	if old_weapon == new_weapon then
		return
	end
	if ctf_modebase.current_mode ~= "chaos" then
		local old_def = old_weapon and weapons[old_weapon]
		if old_def and old_def.on_unwield then
			old_def.on_unwield(player, old_weapon)
		end
		ctf_mode_chaos.clear_all_global_effects(player)
		return
	end
	local old_def = old_weapon and weapons[old_weapon]
	if old_def and old_def.on_unwield then
		old_def.on_unwield(player, old_weapon)
	end
	local new_def = new_weapon and weapons[new_weapon]
	if new_def and new_def.on_wield then
		new_def.on_wield(player, new_weapon)
	end
end

-- Returns the number of the weapon's items in the player's hotbar (main
-- inventory slots 1-8). Multiple stacked boosters each count, so effects can
-- scale with the stack size.
local function count_in_hotbar(player, def)
	local inv = player:get_inventory()
	if not inv then
		return 0
	end
	local size = math.min(inv:get_size("main") or 0, 8)
	local count = 0
	for i = 1, size do
		local stack = inv:get_stack("main", i)
		if def.is_weapon_item and def.is_weapon_item(stack:get_name()) then
			count = count + stack:get_count()
		end
	end
	return count
end

-- Rolls back every applied global effect of the player.
function ctf_mode_chaos.clear_all_global_effects(player)
	local pname = PlayerName(player)
	if not pname then
		return
	end
	local applied = active_global[pname]
	if not applied then
		return
	end
	for weapon_id in pairs(applied) do
		local def = weapons[weapon_id]
		if def and def.on_global_clear then
			def.on_global_clear(player, weapon_id)
		end
	end
	active_global[pname] = nil
end

-- Applies the global effects of all weapons whose items are in the player's
-- hotbar and rolls back the ones that left it. Weapons that stack (multiple
-- copies of their item in the hotbar) get re-applied whenever the count
-- changes. Returns true when something changed.
function ctf_mode_chaos.update_global_effects(player)
	local pname = PlayerName(player)
	if not pname then
		return false
	end
	if ctf_modebase.current_mode ~= "chaos" then
		ctf_mode_chaos.clear_all_global_effects(player)
		return false
	end
	if not active_global[pname] then
		active_global[pname] = {}
	end
	local changed = false
	for weapon_id, def in pairs(weapons) do
		if def.on_global then
			local count = count_in_hotbar(player, def)
			local applied = active_global[pname][weapon_id]
			if count > 0 then
				if not applied or applied.count ~= count then
					-- The stack size changed: roll the old effect back, then
					-- apply it again with the new count.
					if applied and def.on_global_clear then
						def.on_global_clear(player, weapon_id)
					end
					active_global[pname][weapon_id] = {
						count = count,
						label = def.on_global(player, weapon_id, count),
					}
					changed = true
				end
			elseif applied then
				if def.on_global_clear then
					def.on_global_clear(player, weapon_id)
				end
				active_global[pname][weapon_id] = nil
				changed = true
			end
		end
	end
	return changed
end

-- Immediately re-applies the global effect of a single weapon. Used after an
-- upgrade is applied or removed, so effects that depend on param levels (e.g.
-- the shield's Vitality hp bonus or the bunny sword's jump) react right away
-- instead of waiting for the periodic hotbar scan. No-op when the weapon's
-- item is not in the player's hotbar.
function ctf_mode_chaos.refresh_global_effect(player, weapon_id)
	local pname = PlayerName(player)
	if not pname then
		return false
	end
	if ctf_modebase.current_mode ~= "chaos" then
		ctf_mode_chaos.clear_all_global_effects(player)
		return false
	end
	local def = weapons[weapon_id]
	if not def or not def.on_global then
		return false
	end
	if not active_global[pname] then
		active_global[pname] = {}
	end

	local count = count_in_hotbar(player, def)
	local applied = active_global[pname][weapon_id]
	if count > 0 then
		-- Roll the old effect back, then apply it again with the new upgrade
		-- state so it picks up the changed param levels.
		if applied and def.on_global_clear then
			def.on_global_clear(player, weapon_id)
		end
		active_global[pname][weapon_id] = {
			count = count,
			label = def.on_global(player, weapon_id, count),
		}
		return true
	elseif applied then
		if def.on_global_clear then
			def.on_global_clear(player, weapon_id)
		end
		active_global[pname][weapon_id] = nil
	end
	return false
end

-- Returns the HUD labels of all currently active global effects.
function ctf_mode_chaos.get_active_global_effects(player)
	local pname = PlayerName(player)
	if not pname then
		return {}
	end
	local labels = {}
	local applied = active_global[pname]
	if applied then
		for weapon_id, info in pairs(applied) do
			if info and info.label then
				table.insert(labels, info.label)
			end
		end
		table.sort(labels)
	end
	return labels
end

-- Returns the display name of a mode or param key belonging to a weapon.
function ctf_mode_chaos.get_display_name(weapon_id, key)
	weapon_id = weapon_id or default_weapon
	local def = weapons[weapon_id]
	if def then
		if def.mode_mods[key] then
			return def.mode_mods[key].description
		end
		if def.param_defs[key] then
			return def.param_defs[key].description
		end
	end
	return key
end

function ctf_mode_chaos.get_short_name(weapon_id, mode)
	weapon_id = weapon_id or default_weapon
	local def = weapons[weapon_id]
	if def and def.short_names and def.short_names[mode] then
		return def.short_names[mode]
	end
	return short_names[mode] or ctf_mode_chaos.get_display_name(weapon_id, mode)
end

-- Mod item queries --

-- Returns information about a weapon mod item: { kind = "mode"|"param",
-- key = key, shared = bool, weapon_id = id }. Shared mods (info.shared) are a
-- single item shared by every weapon listing the key, so weapon_id is just the
-- first matching weapon. Returns nil for items that are not weapon mods.
function ctf_mode_chaos.get_mod_item_info(item_name)
	for weapon_id, def in pairs(weapons) do
		for key, info in pairs(def.mode_mods) do
			if mod_item_name(def, key, info) == item_name then
				return { kind = "mode", key = key, shared = info.shared, weapon_id = weapon_id }
			end
		end
		for key, info in pairs(def.param_defs) do
			if mod_item_name(def, key, info) == item_name then
				return { kind = "param", key = key, shared = info.shared, weapon_id = weapon_id }
			end
		end
	end
	return nil
end

-- Returns true when the player can install the mod item right now. Non-mod
-- items always return true, so shops can check every listed item uniformly.
-- When the player cannot install the mod (weapon not owned, already unlocked,
-- or at max level) returns false plus a human-readable reason.
function ctf_mode_chaos.get_mod_install_status(player, item_name)
	local info = ctf_mode_chaos.get_mod_item_info(item_name)
	if not info then
		return true
	end

	if info.shared then
		-- The mod applies to every weapon listing the key: any owned weapon
		-- that still accepts it is enough.
		local any_owned = false
		for weapon_id, def in pairs(weapons) do
			local def_info = def.mode_mods[info.key] or def.param_defs[info.key]
			if def_info then
				if shared_target(player, info.key, weapon_id, def) then
					return true
				end
				any_owned = any_owned or player_owns_weapon(def, player)
			end
		end
		if not any_owned then
			return false, "You need a compatible weapon to install this mod!"
		end
		return false, "This mod is already unlocked or at max level!"
	end

	local def = weapons[info.weapon_id]
	if not def then
		return false, "Unknown weapon, please report this to the server staff!"
	end
	if not player_owns_weapon(def, player) then
		return false, "You need the " .. def.description .. " to install this mod!"
	end
	if info.kind == "mode" then
		if ctf_mode_chaos.has_mode(player, info.weapon_id, info.key) then
			return false, "That mode is already unlocked!"
		end
		return true
	end
	if ctf_mode_chaos.param_level(player, info.weapon_id, info.key)
		>= def.param_defs[info.key].max_level then
		return false, "That mod is already at max level!"
	end
	return true
end

-- Upgrades --
function ctf_mode_chaos.has_mode(player, weapon_id, mode)
	weapon_id = weapon_id or default_weapon
	local def = weapons[weapon_id]
	if not def then
		return false
	end
	return mode == def.base_mode or get_upgrades(player, weapon_id).modes[mode] == true
end

function ctf_mode_chaos.add_mode(player, weapon_id, mode)
	weapon_id = weapon_id or default_weapon
	if not weapons[weapon_id] then
		return false
	end
	local u = get_upgrades(player, weapon_id)
	if u.modes[mode] then
		return false
	end
	u.modes[mode] = true
	set_upgrades(player, weapon_id, u)
	return true
end

function ctf_mode_chaos.param_level(player, weapon_id, param)
	weapon_id = weapon_id or default_weapon
	return get_upgrades(player, weapon_id).params[param] or 0
end

function ctf_mode_chaos.add_param(player, weapon_id, param)
	weapon_id = weapon_id or default_weapon
	local def = weapons[weapon_id]
	if not def or not def.param_defs[param] then
		return false
	end
	local u = get_upgrades(player, weapon_id)
	local level = u.params[param] or 0
	if level >= def.param_defs[param].max_level then
		return false
	end
	u.params[param] = level + 1
	set_upgrades(player, weapon_id, u)
	return true
end

function ctf_mode_chaos.get_current_mode(player, weapon_id)
	weapon_id = weapon_id or default_weapon
	local def = weapons[weapon_id]
	if not def then
		return nil
	end
	local pname = PlayerName(player)
	local mode = pname and current_mode[pname] and current_mode[pname][weapon_id]
	if not mode or not ctf_mode_chaos.has_mode(player, weapon_id, mode) then
		return def.base_mode
	end
	return mode
end

function ctf_mode_chaos.set_current_mode(player, weapon_id, mode)
	weapon_id = weapon_id or default_weapon
	if not weapons[weapon_id] then
		return
	end
	local pname = PlayerName(player)
	if not pname then
		return
	end
	if not current_mode[pname] then
		current_mode[pname] = {}
	end
	current_mode[pname][weapon_id] = mode
end

function ctf_mode_chaos.get_unlocked_modes(player, weapon_id)
	weapon_id = weapon_id or default_weapon
	local def = weapons[weapon_id]
	if not def then
		return {}
	end
	local u = get_upgrades(player, weapon_id)
	local list = {}
	for _, mode in ipairs(def.mode_order) do
		if mode == def.base_mode or u.modes[mode] then
			table.insert(list, mode)
		end
	end
	return list
end

-- Picks a random mod item from the drop pools of all registered weapons.
-- Shared mods are one item per modifier key, so their weights are summed
-- across the weapons that list them.
function ctf_mode_chaos.get_random_modifier()
	local entries = {} -- item name -> weight
	for _, def in pairs(weapons) do
		for mode, info in pairs(def.mode_mods) do
			local item = mod_item_name(def, mode, info)
			entries[item] = (entries[item] or 0) + (info.weight or 1)
		end
		for param, info in pairs(def.param_defs) do
			local item = mod_item_name(def, param, info)
			entries[item] = (entries[item] or 0) + (info.weight or 1)
		end
	end

	local total = 0
	for _, weight in pairs(entries) do
		total = total + weight
	end
	if total > 0 then
		local roll = math.random(total)
		local acc = 0
		for item, weight in pairs(entries) do
			acc = acc + weight
			if roll <= acc then
				return item
			end
		end
	end

	-- Fallback: the first weapon that has a mode mod, then a legacy item name.
	for _, def in pairs(weapons) do
		local first = next(def.mode_mods)
		if first then
			return mod_item_name(def, first, def.mode_mods[first])
		end
	end
	return nil
end

-- Applies a modifier to a weapon. kind is "mode" or "param".
-- Returns ok, message.
function ctf_mode_chaos.apply_mod(player, kind, key, weapon_id)
	weapon_id = weapon_id or default_weapon
	local def = weapons[weapon_id]
	if not def then
		return false, "Unknown weapon, please report this to the server staff!"
	end

	if kind == "mode" then
		if not def.mode_mods[key] then
			return false, "Unknown modifier, please report this to the server staff!"
		end
		if ctf_mode_chaos.has_mode(player, weapon_id, key) then
			return false, "That mode is already unlocked!"
		end
		ctf_mode_chaos.add_mode(player, weapon_id, key)
		ctf_mode_chaos.refresh_global_effect(player, weapon_id)
		return true, "New mode unlocked!"
	end

	local pdef = def.param_defs[key]
	if not pdef then
		return false, "Unknown modifier, please report this to the server staff!"
	end
	if ctf_mode_chaos.param_level(player, weapon_id, key) >= pdef.max_level then
		return false, "That mod is already at max level!"
	end
	ctf_mode_chaos.add_param(player, weapon_id, key)
	ctf_mode_chaos.refresh_global_effect(player, weapon_id)
	return true, pdef.description .. " has been applied!"
end

function ctf_mode_chaos.remove_random_upgrade(player)
	local candidates = {}
	local function collect(weapon_id)
		local def = weapons[weapon_id]
		if not def then
			return
		end
		local u = get_upgrades(player, weapon_id)
		for mode, unlocked in pairs(u.modes) do
			if unlocked and mode ~= def.base_mode then
				table.insert(candidates, {
					weapon = weapon_id,
					kind = "mode",
					key = mode,
				})
			end
		end
		for param, level in pairs(u.params) do
			if level > 0 then
				table.insert(candidates, {
					weapon = weapon_id,
					kind = "param",
					key = param,
				})
			end
		end
	end

	-- Prefer the wielded weapon, then fall back to any other weapon.
	local wielded = ctf_mode_chaos.get_wielded_weapon(player)
	if wielded then
		collect(wielded)
	end
	if #candidates == 0 then
		for weapon_id in pairs(weapons) do
			if weapon_id ~= wielded then
				collect(weapon_id)
			end
		end
	end

	if #candidates == 0 then
		return nil
	end

	local pick = candidates[math.random(#candidates)]
	local u = get_upgrades(player, pick.weapon)
	if pick.kind == "mode" then
		u.modes[pick.key] = nil
	else
		u.params[pick.key] = (u.params[pick.key] or 1) - 1
		if u.params[pick.key] <= 0 then
			u.params[pick.key] = nil
		end
	end
	set_upgrades(player, pick.weapon, u)
	ctf_mode_chaos.refresh_global_effect(player, pick.weapon)

	-- Item string of the lost mod, so the caller can drop it as a collectible
	-- (e.g. at the player's death position).
	local def = weapons[pick.weapon]
	local info = pick.kind == "mode" and def.mode_mods[pick.key] or def.param_defs[pick.key]
	pick.item_name = mod_item_name(def, pick.key, info)

	return pick
end

-- Clears all persisted weapon state for a player and rolls back active effects.
-- This is the public rollback/cleanup API used when leaving chaos gameplay,
-- finishing a match, or entering Elysium.
function ctf_mode_chaos.clear_player_state(player)
	local pname = PlayerName(player)
	if not pname then
		return
	end

	local weapon_id = last_wielded_weapon[pname]
	if weapon_id then
		local def = weapons[weapon_id]
		if def and def.on_unwield then
			def.on_unwield(player, weapon_id)
		end
		last_wielded_weapon[pname] = nil
	end

	ctf_mode_chaos.clear_all_global_effects(player)
	ctf_mode_chaos.remove_hud(player)
	upgrades[pname] = {}
	current_mode[pname] = {}
	-- Reset hp to default
	player:set_properties({ hp_max = 20 })
end

function ctf_mode_chaos.update_hud(player)
	local weapon_id = ctf_mode_chaos.get_wielded_weapon(player)
	local globals = ctf_mode_chaos.get_active_global_effects(player)

	if not weapon_id and #globals == 0 then
		ctf_mode_chaos.remove_hud(player)
		return
	end

	local def = weapons[weapon_id]
	local lines = {}

	if def then
		local current = ctf_mode_chaos.get_current_mode(player, weapon_id)
		local unlocked = ctf_mode_chaos.get_unlocked_modes(player, weapon_id)
		local ups = get_upgrades(player, weapon_id)

		lines[#lines + 1] = hud_colors.white .. "[" .. def.description .. "]"

		if #def.mode_order > 1 then
			local modes = {}
			for _, mode in ipairs(unlocked) do
				if mode == current then
					table.insert(lines,
						hud_colors.gold .. "» " .. ctf_mode_chaos.get_short_name(weapon_id, current))
				else
					table.insert(modes, hud_colors.gray .. ctf_mode_chaos.get_short_name(weapon_id, mode))
				end
			end
			table.insert(lines, table.concat(modes, hud_colors.white .. " · "))
		end

		-- Param upgrades
		local mods = {}
		for param, pdef in pairs(def.param_defs) do
			local level = ups.params[param] or 0
			if level > 0 then
				table.insert(mods, hud_colors.green .. pdef.description .. " Lv" .. level)
			end
		end
		if #mods > 0 then
			table.insert(
				lines,
				hud_colors.white .. "Upgrades: " .. table.concat(mods, hud_colors.white .. ", ")
			)
		else
			table.insert(lines, hud_colors.gray .. "Upgrades: none")
		end
	end

	if #globals > 0 then
		table.insert(
			lines,
			hud_colors.cyan .. "● " .. table.concat(globals, hud_colors.white .. ", ")
		)
	end

	local text = table.concat(lines, "\n")

	local hdef = {
		type = "text",
		position = { x = 1, y = 0.25 },
		alignment = { x = "left", y = "down" },
		offset = { x = -6, y = 0 },
		text = text,
		color = 0xF00000,
	}

	if hud:exists(player, HUD_NAME) then
		hud:change(player, HUD_NAME, { text = text })
	else
		hud:add(player, HUD_NAME, hdef)
	end
end

function ctf_mode_chaos.remove_hud(player)
	if player and player:is_player() and hud:exists(player, HUD_NAME) then
		hud:remove(player, HUD_NAME)
	end
end

-- Update the HUD for team members
local timer = 0
core.register_globalstep(function(dtime)
	if ctf_modebase.current_mode ~= "chaos" then
		return
	end
	timer = timer + dtime
	if timer < UPDATE_INTERVAL then
		return
	end
	timer = 0

	for _, player in ipairs(core.get_connected_players()) do
		local pname = player:get_player_name()
		if ctf_teams.get(pname) then
			-- Optimization: only update the HUD when the wielded weapon changes
			local current_weapon = ctf_mode_chaos.get_wielded_weapon(player)
			if last_wielded_weapon[pname] ~= current_weapon then
				ctf_mode_chaos.on_weapon_switch(player, last_wielded_weapon[pname], current_weapon)
				last_wielded_weapon[pname] = current_weapon
				ctf_mode_chaos.update_hud(player)
			end

			-- Global effects react to the hotbar (slots 1-8) contents
			if ctf_mode_chaos.update_global_effects(player) then
				ctf_mode_chaos.update_hud(player)
			end
		end
	end
end)

-- Roll back applied weapon effects when the player leaves the game.
-- core.register_on_leaveplayer(function(player)
-- 	ctf_mode_chaos.clear_player_state(player)
-- end)

-- Roll back applied weapon effects at the end of the match.
ctf_api.register_on_match_end(function()
	for pname, weapon_id in pairs(last_wielded_weapon) do
		local player = core.get_player_by_name(pname)
		if player then
			ctf_mode_chaos.clear_player_state(player)
		end
	end
	for pname, _ in pairs(active_global) do
		local player = core.get_player_by_name(pname)
		if player then
			ctf_mode_chaos.clear_player_state(player)
		end
	end
	last_wielded_weapon = {}
	active_global = {}
end)

function ctf_mode_chaos.can_use()
	if ctf_modebase.current_mode ~= "chaos" then
		return false
	end

	return true
end
