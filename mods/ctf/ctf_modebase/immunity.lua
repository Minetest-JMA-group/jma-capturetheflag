local hud = mhud.init()

local RESPAWN_IMMUNITY_SECONDS = 10
local MAX_DISTANCE_FROM_FLAG = 5
local CHECK_INTERVAL = 1
-- The value is a table if it's respawn immunity and false if it's a custom immunity
local immune_players = {}

function ctf_modebase.is_immune(player)
	return immune_players[PlayerName(player)] ~= nil
end

local old_get_skin = ctf_cosmetics.get_skin
---@diagnostic disable-next-line: duplicate-set-field
ctf_cosmetics.get_skin = function(player, color)
	if ctf_modebase.is_immune(player) then
		return old_get_skin(player, color) .. "^[colorize:#fff:80^[multiply:#85beff"
	else
		return old_get_skin(player, color)
	end
end

function ctf_modebase.give_immunity(
	player,
	respawn_timer,
	apply_callback,
	finish_callback
)
	local pname = player:get_player_name()
	local old = immune_players[pname]

	if old then
		if old.timer then
			old.timer:cancel()
		end

		if old.particles then
			core.delete_particlespawner(old.particles, pname)
		end

		hud:remove(player, "immunity_overlay_text")
	end

	if respawn_timer then
		immune_players[pname] = {
			timer = core.after(respawn_timer, ctf_modebase.remove_immunity, player),
		}
	else
		immune_players[pname] = {
			timer = false,
		}
	end

	immune_players[pname].particles = core.add_particlespawner({
		time = respawn_timer or 0,
		amount = 8 * (respawn_timer or 1),
		collisiondetection = false,
		texture = "ctf_modebase_immune.png",
		glow = 10,
		attached = player,

		pos = vector.new(0, 1.2, 0),
		attract = {
			kind = "point",
			strength = {min = 2, max = 2},
			origin = vector.new(0, 1.2, 0),
			origin_attached = player,
			die_on_contact = true,
		},
		radius = { min = 0.8, max = 1.3, bias = 1.0 },

		minexptime = 0.3,
		maxexptime = 0.3,
		minsize = 1,
		maxsize = 2,
	})

	immune_players[pname].finish_callback = finish_callback

	hud:add(player, "immunity_overlay_text", {
		type = "text",
		position = { x = 0.5, y = 0.1 },
		text = "You are immune!",
		style = 1,
		text_scale = 2,
		color = 0x85beff,
	})

	if old == nil then
		if not apply_callback then
			player_api.set_texture(player, 1, ctf_cosmetics.get_skin(player))
			player:set_properties({ pointable = false })
			player:set_armor_groups({ fleshy = 0 })
		else
			apply_callback(player)
		end
	end
end

function ctf_modebase.remove_immunity(player)
	local pname = player:get_player_name()
	local old = immune_players[pname]

	if old == nil then
		return
	end

	if old.timer then
		old.timer:cancel()
	end

	if old.particles then
		core.delete_particlespawner(old.particles)
	end

	local finish_callback = old.finish_callback

	immune_players[pname] = nil

	hud:remove(player, "immunity_overlay_text")

	if finish_callback then
		finish_callback(player)
		return
	end

	player_api.set_texture(player, 1, ctf_cosmetics.get_skin(player))

	player:set_properties({ pointable = true })
	player:set_armor_groups({ fleshy = 100 })
end

-- Remove immunity and return true if it's respawn immunity, return false otherwise
function ctf_modebase.remove_respawn_immunity(player)
	local pname = player:get_player_name()
	local old = immune_players[pname]

	if old == nil then
		return true
	end
	if old.timer == false then
		return false
	end

	local finish_callback = old.finish_callback

	immune_players[pname] = nil

	old.timer:cancel()

	core.delete_particlespawner(old.particles, pname)

	hud:remove(player, "immunity_overlay_text")

	if finish_callback then
		finish_callback(player)
		return true
	end

	player_api.set_texture(player, 1, ctf_cosmetics.get_skin(player))

	player:set_properties({ pointable = true })
	player:set_armor_groups({ fleshy = 100 })

	return true
end

ctf_teams.register_on_allocplayer(function(player)
	ctf_modebase.give_immunity(player, RESPAWN_IMMUNITY_SECONDS)
end)

ctf_api.register_on_respawnplayer(function(player)
	if not ctf_teams.non_team_players[player:get_player_name()] then
		ctf_modebase.give_immunity(player, RESPAWN_IMMUNITY_SECONDS)
	end
end)

core.register_on_dieplayer(function(player)
	ctf_modebase.remove_immunity(player)
	player:set_properties({ pointable = false })
end)

core.register_on_leaveplayer(function(player)
	ctf_modebase.remove_immunity(player)
end)

core.register_on_punchplayer(function (player, hitter, time_from_last_punch, tool_capabilities, dir, damage)
	if not player or not hitter then
		return
	end

	if not ctf_modebase.is_immune(hitter) then
		return
	end

	local pteam, hteam = ctf_teams.get(player), ctf_teams.get(hitter)
	if not pteam == hteam then
		ctf_modebase.remove_respawn_immunity(hitter)
	end
end)

local last_check = 0
core.register_globalstep(function (dtime)
	last_check = last_check + dtime

	if last_check <= CHECK_INTERVAL then
		return
	end

	last_check = 0
	for player, _ in pairs(immune_players) do
		local player_obj = PlayerObj(player)
		if player_obj then
			local team_color = ctf_teams.get(player_obj)
			local team = ctf_map.current_map.teams[team_color]

			local distance_from_flag = vector.distance(player_obj:get_pos(), team.flag_pos)
			if distance_from_flag > MAX_DISTANCE_FROM_FLAG then
				ctf_modebase.remove_respawn_immunity(player_obj)
			end
		end
	end
end)

core.register_on_placenode(function(pos, newnode, placer, oldnode, itemstack, pointed_thing)
	if not placer then
		return
	end

	if not ctf_modebase.is_immune(placer) then
		return
	end

	ctf_modebase.remove_respawn_immunity(placer)
end)

core.register_on_dignode(function(pos, oldnode, digger)
	if not digger then
		return
	end

	if not ctf_modebase.is_immune(digger) then
		return
	end

	ctf_modebase.remove_respawn_immunity(digger)
end)
