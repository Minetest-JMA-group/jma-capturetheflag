ctf_jma_elysium = {
	modpath = core.get_modpath("ctf_jma_elysium"),
	players = {},
	maps = {},
	loaded_maps = {},
	on_joining = {}
}
local storage = core.get_mod_storage()
local SPAWNTP_COOLDOWN = ctf_core.init_cooldowns()

function ctf_jma_elysium.register_map(name, def)
	ctf_jma_elysium.maps[name] = {
		file = def.file,

		pos1 = vector.add(def.pos, def.bounds.pos1),
		pos2 = vector.add(def.pos, def.bounds.pos2),

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
	if not name then return nil end
	return ctf_jma_elysium.players[name]
end

function ctf_jma_elysium.get_player_list()
	local list = {}
	for name, _ in pairs(ctf_jma_elysium.players) do
		table.insert(list, name)
	end
	return list
end

core.register_on_leaveplayer(function(player)
	local name = player:get_player_name()
	ctf_jma_elysium.players[name] = nil
end)

core.register_on_dieplayer(function(player)
	local pctx = ctf_jma_elysium.get_player(player)
	if pctx then
		ctf_modebase.prepare_respawn_delay(player, 3, function()
			ctf_modebase.give_immunity(player, 3, nil, function()
				player_api.set_texture(player, 1, ctf_cosmetics.get_skin(player))
				player:set_properties({pointable = pctx.pvp})
				player:set_armor_groups({fleshy = 100})
			end)
		end)
	end
end)

function ctf_jma_elysium.can_hit_player(target, hitter)
	local hitter_ctx = ctf_jma_elysium.players[hitter:get_player_name()]
	local target_ctx = ctf_jma_elysium.players[target:get_player_name()]

	if (hitter_ctx and hitter_ctx.pvp == true) and (target_ctx and target_ctx.pvp == true) then
		-- if ctf_core.pos_inside(target:get_pos(), map.no_pvp_zone.pos1, map.no_pvp_zone.pos2) then
		-- 	hud_events.new(hitter, {
		-- 		quick = true,
		-- 		text = "You cannot fight inside the safe area!",
		-- 		color = "warning",
		-- 	})
		-- 	return false
		-- end

		return true
	end

	return false
end

function ctf_modebase.player.is_playing(player)
	if ctf_jma_elysium.players[player:get_player_name()] then
		return false
	end
	return true
end

function ctf_jma_elysium.set_pvp_mode(player, mode)
	if not player then return end
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

		player:set_properties({pointable = pointable,})
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

function ctf_jma_elysium.join(player, joined_callback)
	local name = player:get_player_name()

	if player:get_attach() then
		core.chat_send_player(name, "Don't try to breaks the game, please!")
		return false
	end

	local map = ctf_jma_elysium.maps.main

	local function handle_player()
		ctf_jma_elysium.on_joining[name] = nil
		if not core.get_player_by_name(name) then return end
		ctf_jma_elysium.players[name] = {
			pvp = false,
			location = "main"
		}
		core.chat_send_all(name .. " has joined Elysium.")

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
		player:set_armor_groups({fleshy = 100})
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

		core.log("action", "[ctf_jma_elysium] Player " .. name .. " has joined Elysium.")
	end

	ctf_jma_elysium.on_joining[name] = true
	if not ctf_jma_elysium.loaded_maps.main then
		core.chat_send_player(name, "Please wait a moment while we prepare the map...")

		ctf_map.emerge_with_callbacks(nil, map.pos1, map.pos2, function()
			core.place_schematic(map.pos1, map.file, 0)
			ctf_jma_elysium.loaded_maps.main = true
			ctf_jma_elysium.restore_nodemeta("main")
			core.after(1, handle_player)
		end)

		return true
	end

	core.after(3, handle_player)
end

function ctf_jma_elysium.leave(player)
	local name = player:get_player_name()

	if player:get_attach() then
		core.chat_send_player(name, "Don't try to breaks the game, please!")
		return false
	end

	if player:get_hp() == 0 then
		core.chat_send_player(name, "You cannot leave Elysium while you are dead! Please wait until you respawn.")
		return false
	end

	core.chat_send_all(name .. " has left Elysium.")

	local inv = player:get_inventory()
	inv:set_list("main", {})

	player:override_day_night_ratio(0)

	ctf_modebase.remove_immunity(player)

	ctf_teams.non_team_players[name] = nil
	ctf_jma_elysium.players[name] = nil

	ctf_modebase.player.update(player)
	ctf_jma_leagues.update_icon(player)
	ctf_teams.allocate_player(player, true)

	core.log("action", "[ctf_jma_elysium] Player " .. name .. " has left Elysium.")
	return true
end

ctf_jma_elysium.register_map("main", {
	file = ctf_jma_elysium.modpath .. "/maps/jma_elysium_hub.mts",
	bounds = {
		pos1 = {x = 0, y = 0, z = 0},
		pos2 = {x = 226, y = 124, z = 222},
	},
	pos = {x = 0, y = 500, z = 0},
	spawn = {x = 115, y = 21, z = 111},
	no_pvp_zone = {
		pos1 = {x = 5, y = 1, z = 5},
		pos2 = {x = 15, y = 15, z = 15}
	}
})

core.register_chatcommand("elist", {
	description = "List all players in Elysium",
	func = function()
		local players = ctf_jma_elysium.get_player_list()
		if #players == 0 then
			return false, "No players in Elysium."
		end

		local msg = string .format("Players in Elysium (%d): %s", #players, table.concat(players, ", "))
		return true, msg
	end
})

core.register_chatcommand("espawn", {
	description = "Teleport to Elysium spawn point",
	privs = {interact = true},
	func = function(name, param)
		local player = core.get_player_by_name(name)
		if not player then
			return false, "You must be online to use this command."
		end

		local pctx = ctf_jma_elysium.get_player(player)
		if not pctx then
			return false, "You are not in Elysium."
		end

		if SPAWNTP_COOLDOWN:get(player) then
			return false, "Not too fast!"
		end

		if player:get_hp() == 0 then
			return false, "You cannot use this command while dead."
		end

		if player:get_attach() then
			return false, "You cannot use this command right now."
		end

		local map = ctf_jma_elysium.maps.main

		SPAWNTP_COOLDOWN:set(player, 3)
		player:set_pos(map.spawn_abs)
		return true, "Teleported."
	end
})

local allow_reset = {}
core.register_chatcommand("el_reset", {
	description = "Reset Elysium modstorage (dangerous, admin only)",
	privs = {ctf_admin = true, server = true},
	func = function(name)
		if not allow_reset[name] then
			allow_reset[name] = true
			minetest.after(30, function()
				allow_reset[name] = nil
			end)
			return true, "Please re-run this command to confirm reset. This action cannot be undone."
		end
		storage:from_table({})
		core.log("action", "[ctf_jma_elysium] Elysium modstorage has been reset by " .. name)
		return true, "Elysium modstorage has been reset."
	end
})

ctf_core.include_files("things.lua", "map_utils.lua", "elysium_access.lua")
