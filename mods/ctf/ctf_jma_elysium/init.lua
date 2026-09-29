ctf_jma_elysium = {
	modpath = core.get_modpath("ctf_jma_elysium"),
	INVITE_TIMEOUT_SECONDS = 60,
	players = {},
	callbacks = {
		on_prejoin = {},
		on_join = {},
		on_leave = {},
	},
	maps = {},
	loaded_maps = {},
	on_joining = {},
	elysium_locked = false,

	-- Kill list feed of the Elysium hub (see ctf_kill_list)
	kill_list = {},

	-- PvP Boxes
	boxes = {},
	box_invites = {},
	box_invite_timers = {},
	box_templates = {},
	box_reserved_ids = {},
	box_creating = {},
	box_requests = {},
	box_warnings = {},
}
local S = core.get_translator(core.get_current_modname())
local storage = core.get_mod_storage()
local SPAWNTP_COOLDOWN = ctf_core.init_cooldowns()
local FORMNAME_WAIT = "ctf_jma_elysium:wait"

-- Reads the X/Y/Z size stored in a Minetest schematic (.mts) header.
-- Layout: u32 magic "MTSM", u16 version, u16 size_x, u16 size_y, u16 size_z
-- (all integers are stored big-endian).
function ctf_jma_elysium.read_mts_size(path)
	local file = io.open(path, "rb")
	if not file then
		return nil
	end

	local header = file:read(12)
	file:close()

	if not header or #header < 12 then
		return nil
	end

	local function u16be(offset)
		return header:byte(offset) * 256 + header:byte(offset + 1)
	end

	return {
		x = u16be(7),
		y = u16be(9),
		z = u16be(11),
	}
end

function ctf_jma_elysium.register_map(name, def)
	local bounds = def.bounds
	if not bounds then
		-- Auto-detect the bounds from the schematic size
		local size = def.size or ctf_jma_elysium.read_mts_size(def.file)
		if not size then
			core.log(
				"error",
				"[ctf_jma_elysium] Failed to detect size of map: " .. name
			)
			return
		end
		bounds = {
			pos1 = { x = 0, y = 0, z = 0 },
			pos2 = { x = size.x - 1, y = size.y - 1, z = size.z - 1 },
		}
	end

	ctf_jma_elysium.maps[name] = {
		file = def.file,

		pos1 = vector.add(def.pos, bounds.pos1),
		pos2 = vector.add(def.pos, bounds.pos2),

		map_offset = def.map_offset or vector.new(0, 0, 0),

		bounds1 = def.bounds1,
		bounds2 = def.bounds2,

		spawn = vector.add(def.pos, def.spawn),
		spawn_abs = vector.add(def.pos, def.spawn),

		no_pvp_zone = {
			pos1 = vector.add(def.pos, def.no_pvp_zone.pos1),
			pos2 = vector.add(def.pos, def.no_pvp_zone.pos2),
		},
	}
	core.log("action", "[ctf_jma_elysium] Registered map: " .. name)
end

function ctf_jma_elysium.get_player(player)
	local name = PlayerName(player)
	if not name then
		return nil
	end
	return ctf_jma_elysium.players[name]
end

function ctf_jma_elysium.get_player_list()
	local list = {}
	for name, _ in pairs(ctf_jma_elysium.players) do
		table.insert(list, name)
	end
	return list
end

---Sends a message to every player that is currently in Elysium
---@param msg string
function ctf_jma_elysium.broadcast(msg)
	for _, name in ipairs(ctf_jma_elysium.get_player_list()) do
		core.chat_send_player(name, msg)
	end
end

function ctf_jma_elysium.register_on_join(callback)
	table.insert(ctf_jma_elysium.callbacks.on_join, callback)
end

function ctf_jma_elysium.register_on_prejoin(callback)
	table.insert(ctf_jma_elysium.callbacks.on_prejoin, callback)
end

function ctf_jma_elysium.register_on_leave(callback)
	table.insert(ctf_jma_elysium.callbacks.on_leave, callback)
end

core.register_on_leaveplayer(function(player)
	local name = player:get_player_name()
	ctf_jma_elysium.players[name] = nil
end)

-- Elysium and every PvP Box have their own kill list feed, so a player always
-- sees the kills of the place he is currently in
ctf_kill_list.feed_provider = function(name)
	local ctx = ctf_jma_elysium.players[name]
	if not ctx then
		return nil
	end

	if ctx.box then
		local box = ctf_jma_elysium.boxes[ctx.box]
		if box then
			box.kill_list = box.kill_list or {}
			return box.kill_list
		end
	end

	return ctf_jma_elysium.kill_list
end

-- Image shown in the kill list when nobody is to blame
local function death_image(reason)
	if type(reason) == "table" then
		if reason.type == "fall" then
			return "ctf_kill_list_falling_man.png"
		end

		if reason.type == "drown" then
			return "bubble.png"
		end

		if reason.type == "node_damage" and reason.node then
			if reason.node:find("lava") then
				return "default_lava.png"
			end

			local def = core.registered_nodes[reason.node]
			if def and def.inventory_image and def.inventory_image ~= "" then
				return def.inventory_image
			end
		end
	end

	return "ctf_modebase_skull.png"
end

-- Last player that hit someone inside Elysium. The regular match tracks this
-- in ctf_combat_mode, but that ignores players without a team.
local last_hitter = {}
local HITTER_TIMEOUT = 10

core.register_on_punchplayer(function(player, hitter, _, tool_capabilities)
	if not hitter or not hitter:is_player() then
		return
	end

	if not ctf_jma_elysium.can_hit_player(player, hitter) then
		return
	end

	local def = hitter:get_wielded_item():get_definition()
	local image = def and def.inventory_image or ""

	last_hitter[player:get_player_name()] = {
		name = hitter:get_player_name(),
		time = core.get_us_time(),
		image = image ~= "" and image or "ctf_kill_list_punch.png",
		ranged = tool_capabilities
			and tool_capabilities.damage_groups
			and tool_capabilities.damage_groups.ranged,
	}
end)

-- Reports a death that happened inside Elysium to the kill list of the area
---@param player ObjectRef
---@param reason table
local function report_kill(player, reason)
	local name = player:get_player_name()
	local hit = last_hitter[name]
	last_hitter[name] = nil

	local killer, image
	if hit and core.get_us_time() - hit.time <= HITTER_TIMEOUT * 1000000 then
		killer = hit.name
		image = hit.image

		if hit.ranged then
			image = image .. "^[transformFX"
		end
	end

	if killer == name then
		-- Killed by his own weapon
		killer, image = "", nil
	end

	ctf_kill_list.add(killer or "", name, image or death_image(reason))
end

core.register_on_dieplayer(function(player, reason)
	local pctx = ctf_jma_elysium.get_player(player)
	if pctx then
		report_kill(player, reason)
		local death_pos = player:get_pos()

		ctf_modebase.prepare_respawn_delay(player, 3, function()
			-- Return the player to a marker, or the captured death position.
			ctf_jma_elysium.respawn_player(player, death_pos)

			ctf_modebase.give_immunity(player, 3, nil, function()
				player_api.set_texture(player, 1, ctf_cosmetics.get_skin(player))
				player:set_properties({ pointable = pctx.pvp })
				player:set_armor_groups({ fleshy = 100 })
			end)
		end)
	end
end)

function ctf_jma_elysium.can_hit_player(target, hitter)
	if not hitter or not target then
		return false
	end

	local hitter_ctx = ctf_jma_elysium.players[hitter:get_player_name()]
	local target_ctx = ctf_jma_elysium.players[target:get_player_name()]

	if not (hitter_ctx and hitter_ctx.pvp == true) then
		return false
	end

	if not (target_ctx and target_ctx.pvp == true) then
		return false
	end

	-- Players inside a PvP Box can only fight members of the same box.
	-- Players outside of any box keep the regular mutual PvP.
	if hitter_ctx.box ~= target_ctx.box then
		return false
	end

	return true
end

function ctf_modebase.player.is_playing(player)
	if ctf_jma_elysium.players[player:get_player_name()] then
		return false
	end
	return true
end

function ctf_jma_elysium.set_pvp_mode(player, mode)
	if not player then
		return
	end
	local name = player:get_player_name()
	local ctx = ctf_jma_elysium.players[name]
	if ctx then
		if mode ~= nil then
			ctx.pvp = mode
		else
			ctx.pvp = not ctx.pvp
		end

		local texture = "ctf_rankings_league_steel.png"
		local pointable = false
		if ctx.pvp == true then
			pointable = true
			texture = "ctf_jma_elysium_mini_sword.png"
		end

		player:set_properties({ pointable = pointable })
		hpbar.set_icon(player, texture)
		return ctx.pvp
	end
end

function ctf_jma_elysium.chat_send_elysium(msg)
	for pname, ctx in pairs(ctf_jma_elysium.players) do
		-- if ctx.location == "main" then -- In plans is to send messages to a specified location or to everyone
		core.chat_send_player(pname, msg)
		-- end
	end
end

function ctf_jma_elysium.can_player_join_elysium(name)
	local player = PlayerObj(name)
	if not player or not player:is_player() then
		return false, ""
	end

	if ctf_jma_elysium.players[name] then
		return false, S("You're already joined Elysium. Use /leave to exit")
	end

	if ctf_jma_elysium.elysium_locked then
		return false, S("Elysium is currently locked by admin.")
	end

	if player:get_hp() <= 0 then
		return false, S("You're a ghost, not a player! Can't join Elysium while dead.")
	end

	if player:get_attach() then
		return false, S("You cannot join Elysium while attached.")
	end

	if ctf_modebase.taken_flags[name] then
		return false,
			S("Dear hacker @1, you cannot join Elysium while holding a flag(s).", name)
	end

	if ctf_combat_mode.in_combat(player) then
		return false,
			S("You cannot join Elysium while in combat. Please wait until combat ends.")
	end

	return true
end

function ctf_jma_elysium.show_wait_formspec(player_name)
	local fs = "formspec_version[7]"
		.. "size[8,3]"
		.. "no_prepend[]"
		.. "hypertext[0,0;8,3;hypertext;<global valign=middle><center><b>"
		.. core.formspec_escape(S("Please wait..."))
		.. "</b></center>]"
	core.show_formspec(player_name, FORMNAME_WAIT, fs)
end

function ctf_jma_elysium.close_wait_formspec(player_name)
	core.close_formspec(player_name, FORMNAME_WAIT)
end

function ctf_jma_elysium.join(player, joined_callback)
	local name = player:get_player_name()
	local map = ctf_jma_elysium.maps.main

	local function handle_player(player)
		local player_name = player:get_player_name()

		local can_join, reason = ctf_jma_elysium.can_player_join_elysium(player_name)
		if not can_join then
			---@cast reason -nil
			core.chat_send_player(player_name, reason)
			ctf_jma_elysium.on_joining[player_name] = nil
			return false
		end

		ctf_jma_elysium.on_joining[player_name] = nil
		ctf_jma_elysium.players[player_name] = {
			pvp = false,
			location = "main",
		}
		-- The kill list switches to the feed of Elysium
		ctf_kill_list.update_player(player)

		core.chat_send_all(S("@1 has joined Elysium.", player_name))
		core.close_formspec(player_name, FORMNAME_WAIT)

		-- Call registered pre-join callbacks before any teleport/team changes
		for _, callback in ipairs(ctf_jma_elysium.callbacks.on_prejoin) do
			callback(player)
		end

		ctf_teams.remove_online_player(player)
		ctf_teams.player_team[name] = nil
		ctf_teams.non_team_players[name] = true

		player:hud_set_hotbar_image("gui_hotbar.png^[colorize:gray:128")
		player:hud_set_hotbar_selected_image("gui_hotbar_selected.png^[multiply:gray")
		player_api.set_texture(player, 1, ctf_cosmetics.get_skin(player))

		playertag.set(player, playertag.TYPE_BUILTIN)

		-- Just in case
		player:set_properties({
			hp_max = 20,
		})
		player:set_armor_groups({ fleshy = 100 })
		player:set_hp(20)

		physics.set(name, "ctf_modebase:map_physics", {
			speed = 1,
			jump = 1,
			gravity = 1,
		})

		player:set_physics_override({
			sneak_glitch = true,
			new_move = true,
		})

		ctf_modebase.update_wear.cancel_player_updates(player)

		local inv = player:get_inventory()
		inv:set_list("main", {})
		if not inv:contains_item("main", "ctf_jma_elysium:pvp_off") then
			inv:add_item("main", "ctf_jma_elysium:pvp_off")
		end
		if not inv:contains_item("main", "default:pick_steel") then
			inv:add_item("main", "default:pick_steel")
		end
		if not inv:contains_item("main", "default:sword_steel") then
			inv:add_item("main", "default:sword_steel")
		end


		-- Daytime always
		skybox.clear(player)
		player:override_day_night_ratio(1)

		local function tp()
			if not ctf_core.pos_inside(player:get_pos(), map.pos1, map.pos2) then
				player:set_pos(map.spawn_abs)
			end
		end

		player:set_pos(map.spawn_abs)
		core.after(0.2, tp)
		ctf_jma_elysium.set_pvp_mode(player, false)

		if joined_callback then
			joined_callback(player, ctf_jma_elysium.players[name])
		end

		-- Call registered callbacks
		for _, callback in ipairs(ctf_jma_elysium.callbacks.on_join) do
			callback(player, ctf_jma_elysium.players[name])
		end

		core.log("action", "[ctf_jma_elysium] Player " .. name .. " has joined Elysium.")
	end

	ctf_jma_elysium.on_joining[name] = true
	if not ctf_jma_elysium.loaded_maps.main then
		ctf_jma_elysium.show_wait_formspec(name)

		ctf_map.emerge_with_callbacks(nil, map.pos1, map.pos2, function()
			core.place_schematic(vector.add(map.pos1, map.map_offset), map.file, "0")
			ctf_jma_elysium.loaded_maps.main = true
			ctf_jma_elysium.restore_nodemeta("main")
			core.after(1, handle_player, player)
		end)

		return true
	end

	ctf_jma_elysium.show_wait_formspec(name)
	core.after(1, handle_player, player)

	return true
end

function ctf_jma_elysium.leave(player)
	local name = player:get_player_name()

	if player:get_attach() then
		core.chat_send_player(name, S("You cannot leave Elysium while attached"))
		return false
	end

	if player:get_hp() == 0 then
		core.chat_send_player(
			name,
			S(
				"You cannot leave Elysium while you are dead! Please wait until you respawn."
			)
		)
		return false
	end

	-- Leave any PvP Box before leaving Elysium
	ctf_jma_elysium.remove_from_box(name)

	core.chat_send_all(S("@1 has left Elysium", name))

	local inv = player:get_inventory()
	inv:set_list("main", {})

	player:override_day_night_ratio(0)

	ctf_modebase.remove_immunity(player)

	ctf_teams.non_team_players[name] = nil

	-- Call registered callbacks before clearing player data
	for _, callback in ipairs(ctf_jma_elysium.callbacks.on_leave) do
		callback(player, ctf_jma_elysium.players[name])
	end

	ctf_jma_elysium.players[name] = nil

	-- The kill list switches back to the feed of the match
	ctf_kill_list.update_player(player)

	ctf_modebase.player.update(player)
	ctf_jma_leagues.update_icon(player)
	ctf_teams.allocate_player(player, true)

	core.log("action", "[ctf_jma_elysium] Player " .. name .. " has left Elysium.")
	return true
end

ctf_jma_elysium.register_map("main", {
	file = ctf_jma_elysium.modpath .. "/maps/jma_elysium_hub.mts",
	-- Bounds are auto-detected from the .mts header (226 x 124 x 222)
	map_offset = { x = 0, y = -1, z = 0 },
	pos = { x = 0, y = 500, z = 0 },
	spawn = { x = 115, y = 21, z = 111 },
	no_pvp_zone = {
		pos1 = { x = 5, y = 1, z = 5 },
		pos2 = { x = 15, y = 15, z = 15 },
	},
})

core.register_chatcommand("elist", {
	description = S("List all players in Elysium"),
	func = function()
		local players = ctf_jma_elysium.get_player_list()
		if #players == 0 then
			return false, S("No players in Elysium.")
		end

		table.sort(players)

		local list = {}
		for _, pname in ipairs(players) do
			local ctx = ctf_jma_elysium.players[pname]
			local box_id = ctx and ctx.box
			if box_id then
				-- Players inside a PvP Box are marked with its id
				table.insert(list, S("@1 (#@2)", pname, box_id))
			else
				table.insert(list, pname)
			end
		end

		local msg =
			S("Players in Elysium (@1): @2", #players, table.concat(list, ", "))
		return true, msg
	end,
})

core.register_chatcommand("espawn", {
	description = S("Teleport to Elysium spawn point"),
	privs = { interact = true },
	func = function(name, param)
		local player = core.get_player_by_name(name)
		if not player then
			return false, S("You must be online to use this command.")
		end

		local pctx = ctf_jma_elysium.get_player(player)
		if not pctx then
			return false, S("You are not in Elysium.")
		end

		if SPAWNTP_COOLDOWN:get(player) then
			return false, S("Not too fast!")
		end

		if player:get_hp() == 0 then
			return false, S("You cannot use this command while dead.")
		end

		if player:get_attach() then
			return false, S("You cannot use this command right now.")
		end

		local map = ctf_jma_elysium.maps.main
		local target_pos = ctf_jma_elysium.get_box_spawn(player) or map.spawn_abs

		SPAWNTP_COOLDOWN:set(player, 3)
		player:set_pos(target_pos)
		return true, S("Teleported.")
	end,
})

local allow_reset = {}
core.register_chatcommand("el_reset", {
	description = S("Reset Elysium modstorage (dangerous, admin only)"),
	privs = { ctf_admin = true, server = true },
	func = function(name)
		if not allow_reset[name] then
			allow_reset[name] = true
			core.after(30, function()
				allow_reset[name] = nil
			end)
			return true,
				S(
					"Please re-run this command to confirm reset. This action cannot be undone."
				)
		end
		storage:from_table({})
		core.log(
			"action",
			"[ctf_jma_elysium] Elysium modstorage has been reset by " .. name
		)
		return true, S("Elysium modstorage has been reset.")
	end,
})

ctf_core.include_files("things.lua", "map_utils.lua", "elysium_access.lua", "boxes.lua")
