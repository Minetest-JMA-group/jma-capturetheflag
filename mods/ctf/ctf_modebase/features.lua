--- @alias Vec3 { x: number, y: number, z: number }
--- @alias Vec2 { x: number, y: number }

--- @type { [string]: number }
local default_item_value = {
	["ctf_melee:sword_diamond"] = 12,
	["ctf_ranged:shotgun_loaded"] = 12,
	["ctf_melee:sword_mese"] = 11,
	["ctf_ranged:shotgun"] = 10,
	["ctf_ranged:sniper_magnum_loaded"] = 12,
	["default:axe_diamond"] = 8,
	["ctf_ranged:sniper_magnum"] = 10,
	["ctf_ranged:assault_rifle_loaded"] = 8,
	["rocket_launcher:launcher"] = 8,
	["default:sword_steel"] = 7,
	["ctf_melee:sword_steel"] = 7,
	["default:pick_diamond"] = 6,
	["ctf_ranged:assault_rifle"] = 6,
	["grenades:frag"] = 6,
	["ctf_healing:medkit"] = 6,
	["default:pick_mese"] = 5,
	["default:axe_mese"] = 5,
	["grenades:poison"] = 5,
	["ctf_ranged:rifle_loaded"] = 5,
	["ctf_ranged:smg_loaded"] = 5,
	["ctf_ranged:rifle"] = 4,
	["ctf_ranged:smg"] = 4,
	["ctf_healing:bandage"] = 4,
	["default:shovel_diamond"] = 4,
	["grenades:smoke"] = 2,
	["ctf_ranged:pistol_loaded"] = 2,
	["default:shovel_steel"] = 2,
	["default:pick_steel"] = 1,
	["default:axe_steel"] = 1,
	["default:shovel_mese"] = 1,
	["ctf_ranged:pistol"] = 1,
}
ctf_core.testing = {
	-- This is here temporarily, I'm modifying it with //lua and a code minimizer on the main server-
	-- -so I don't need to restart for every little change
	-- pkd, kd_diff, actual_kd_diff, players_diff, best_kd, worst_kd, total_players, worst_players, best_players
	--ctf_core.testing.
	testing = true,
	test = function(
		pkd,
		kd_diff,
		actual_kd_diff,
		players_diff,
		best_kd,
		worst_kd,
		total_players,
		worst_players,
		best_players
	)
		local one_third = math.ceil(0.34 * total_players)
		local one_fourth = math.ceil(0.25 * total_players)
		local avg = (kd_diff + actual_kd_diff) / 2
		if best_kd.kills + worst_kd.kills >= 30 then
			avg = actual_kd_diff
		end
		return (best_kd.kills + worst_kd.kills >= 30 and best_kd.t == best_players.t)
			or (
				pkd >= math.min(1, kd_diff / 2)
				and avg >= 0.4
				and (
					players_diff <= one_fourth
					or (pkd >= 1.5 and players_diff <= one_third)
				)
			)
	end,
}

local S = core.get_translator(core.get_current_modname())

local hud = mhud.init()
local LOADING_SCREEN_TARGET_TIME = 5
local loading_screen_time

-- tag: map_image
local old_announce = ctf_modebase.map_chosen
function ctf_modebase.map_chosen(map, ...)
	local found = false
	for _, p in pairs(core.get_connected_players()) do
		if hud:exists(p, "loading_screen") then
			found = true

			hud:add(p, "map_image", {
				type = "image",
				position = { x = 0.5, y = 0.5 },
				image_scale = -100,
				z_index = 1001,
				texture = map.dirname .. "_screenshot.png^[opacity:30",
			})

			hud:change(p, "loading_text", {
				text = S("Loading Map: @1...", map.name),
			})
		end
	end

	-- Reset loading screen timer
	if found then
		loading_screen_time = core.get_us_time()
	end

	return old_announce(map, ...)
end

local function supports_observers(x)
	if x then
		if x.object then
			x = x.object
		end
		if x.get_observers and x:get_pos() then
			return true
		end
	end
	return false
end

local function update_playertag(player, t, nametag, team_nametag, symbol_nametag)
	if
		not supports_observers(nametag.object)
		or not supports_observers(team_nametag.object)
		or not supports_observers(symbol_nametag.object)
	then
		return
	end

	local entity_players = {}
	local nametag_players = table.copy(ctf_teams.online_players[t].players)
	local symbol_players = {}
	nametag_players[player:get_player_name()] = nil

	for n in pairs(table.copy(nametag_players)) do
		local setting = ctf_settings.get(
			core.get_player_by_name(n),
			"ctf_modebase:teammate_nametag_style"
		)

		if setting == "3" then
			nametag_players[n] = nil
		elseif setting == "2" then
			symbol_players[n] = true
			nametag_players[n] = nil
		end
	end

	for k, v in ipairs(core.get_connected_players()) do
		local n = v:get_player_name()
		if not nametag_players[n] then
			entity_players[n] = true
		end
	end

	nametag.object:set_observers(entity_players)
	team_nametag.object:set_observers(nametag_players)
	symbol_nametag.object:set_observers(symbol_players)
end

local tags_hidden = false
local update_timer = false
local function update_playertags(time)
	if not update_timer and not tags_hidden then
		update_timer = true
		core.after(time or 1.2, function()
			update_timer = false
			for _, p in pairs(core.get_connected_players()) do
				local t = ctf_teams.get(p)
				local playertag = playertag.get(p)

				if playertag then
					local team_nametag = playertag.nametag_entity
					local nametag = playertag.entity
					local symbol_entity = playertag.symbol_entity

					if t and nametag and team_nametag and symbol_entity then
						update_playertag(p, t, nametag, team_nametag, symbol_entity)
					end
				end
			end
		end)
	end
end

local PLAYERTAGS_OFF = false
local PLAYERTAGS_ON = true
local function set_playertags_state(state)
	if state == PLAYERTAGS_ON and tags_hidden then
		tags_hidden = false

		update_playertags(0)
	elseif state == PLAYERTAGS_OFF and not tags_hidden then
		tags_hidden = true

		for _, p in pairs(core.get_connected_players()) do
			local playertag = playertag.get(p)

			if ctf_teams.get(p) and playertag then
				local team_nametag = playertag.nametag_entity
				local nametag = playertag.entity
				local symbol_entity = playertag.symbol_entity

				if
					supports_observers(nametag)
					and supports_observers(team_nametag)
					and supports_observers(symbol_entity)
				then
					team_nametag.object:set_observers({})
					symbol_entity.object:set_observers({})
					nametag.object:set_observers({})
				end
			end
		end
	end
end

function ctf_modebase.show_loading_screen()
	set_playertags_state(PLAYERTAGS_OFF)
	for _, p in pairs(core.get_connected_players()) do
		if ctf_teams.get(p) then
			hud:add(p, "loading_screen", {
				type = "image",
				position = { x = 0.5, y = 0.5 },
				image_scale = -100.5,
				z_index = 1000,
				texture = "[combine:1x1^[invert:rgba^[opacity:1^[colorize:#34323d:255",
			})

			-- z_index 1001 is reserved for the next map's image. Search file for `tag: map_image`

			hud:add(p, "loading_text", {
				type = "text",
				position = { x = 0.5, y = 0.5 },
				alignment = { x = "center", y = "up" },
				text_scale = 2,
				text = S("Loading Next Map..."),
				color = 0x7ec5ff,
				z_index = 1002,
			})
			hud:add(p, {
				type = "text",
				position = { x = 0.5, y = 0.75 },
				alignment = { x = "center", y = "center" },
				text = random_messages.get_random_message(),
				color = 0xffffff,
				z_index = 1002,
			})
		end
	end

	loading_screen_time = core.get_us_time()
end

local function is_pro(player, rank)
	local pro_chest = player
		and player
				:get_meta()
				:get_int("ctf_rankings:pro_chest:" .. (ctf_modebase.current_mode or ""))
			== 1

	-- Remember to update /make_pro in ranking_commands.lua if you change anything here
	if pro_chest or rank then
		if
			pro_chest
			or (rank.score or 0) >= 8000
				and (rank.kills or 0) / (rank.deaths or 1) >= 1.4
				and (rank.flag_captures or 0) >= 5
		then
			return true
		end
	end
end

local function flag_event_notify(
	pname,
	pteam,
	flags_taken,
	to_player_msg,
	to_teammates_msg,
	to_victims_msg,
	to_others_msg
)
	if flags_taken and type(flags_taken) == "string" then
		flags_taken = { flags_taken }
	end

	local function send_notify(target, def)
		if
			ctf_settings.get(PlayerObj(target), "ctf_modebase:flag_notifications")
			== "true"
		then
			hud_events.new(target, def)
		end
	end

	if to_player_msg then
		send_notify(pname, {
			text = to_player_msg.text,
			color = to_player_msg.color or "info",
			quick = true,
		})
	end

	for team, tctx in pairs(ctf_teams.online_players) do
		for teammate in pairs(tctx.players) do
			if teammate ~= pname then
				if team == pteam then
					send_notify(teammate, {
						text = to_teammates_msg.text,
						color = to_teammates_msg.color or "info",
						quick = true,
					})
				elseif to_victims_msg and table.indexof(flags_taken, team) ~= -1 then
					send_notify(teammate, {
						text = to_victims_msg.text,
						color = to_victims_msg.color or "warning",
						quick = true,
					})
				else
					send_notify(teammate, {
						text = to_others_msg.text,
						color = to_others_msg.color or "warning",
						quick = true,
					})
				end
			end
		end
	end
end

ctf_settings.register("ctf_modebase:flag_notifications", {
	type = "bool",
	label = S("Show flag event messages"),
	description = S("Toggle visibility of HUD messages about flag-related events"),
	default = "true",
})

ctf_settings.register("ctf_modebase:teammate_nametag_style", {
	type = "list",
	description = S("Controls what style of nametag to use for teammates."),
	list = { "Minetest Nametag: Full", "Minetest Nametag: Symbol", "Entity Nametag" },
	default = "1",
	on_change = function(player, new_value)
		core.log(
			"action",
			"Player " .. player:get_player_name() .. " changed their nametag setting"
		)
		update_playertags()
	end,
})

ctf_modebase.features = function(rankings, recent_rankings)
	local FLAG_MESSAGE_COLOR = "#d9b72a"
	local FLAG_CAPTURE_TIMER = 60 * 3
	local many_teams = false
	local team_list
	local teams_left

	local function calculate_killscore(player, killer)
		local pname = PlayerName(player)
		local killer_name = PlayerName(killer)
		local pteam = ctf_teams.get(pname)
		if not pteam then
			return 0
		end
		local match_rank = recent_rankings.players()[player] or {}
		local match_kd = (match_rank.kills or 1) / (match_rank.deaths or 1)
		local overall_rank = rankings:get(pname)
		local overall_kd = (overall_rank.kills or 1) / (overall_rank.deaths or 1)
		local kd = (1 * overall_kd + 2 * match_kd) / 3

		local val_per_flag = 0.25
		local val_to_add = 0
		local is_killer_flag_thief = false
		for tname, carrier in pairs(ctf_modebase.flag_taken) do
			if tname == pteam then
				-- Since we've got their flag, now it's
				-- much more important to kill our thief.
				-- Right?
				val_per_flag = 0.5
			end
			if carrier.name == player then
				val_to_add = val_to_add + 1
			end
			if carrier.name == killer_name then
				is_killer_flag_thief = true
			end
		end
		if val_to_add > 0 and is_killer_flag_thief then
			val_to_add = val_to_add * 2
		end
		local flag_multiplier = 1 + val_to_add * val_per_flag
		return math.max(1, math.ceil(kd * 7 * flag_multiplier))
	end

	--- @param team Team?
	--- @param target_teams Team[]
	--- @return number
	local function calculate_capture_reward(team, target_teams)
		local team_scores = recent_rankings.teams()
		local capture_reward = 0
		for _, lost_team in ipairs(target_teams) do
			local score = ((team_scores[lost_team] or {}).score or 0) / 4
			score = math.max(10, math.min(900, score))
			capture_reward = capture_reward + score
		end
		return math.ceil(capture_reward)
	end

	--- @param team Team
	--- @param drop_point Vec2
	--- @param drop_reason "timeout" | "death"
	--- @param target_teams Team[]
	--- @return number
	local function calculate_attempt_reward(team, drop_point, drop_reason, target_teams)
		local capture_reward = calculate_capture_reward(team, target_teams)
		if drop_reason == "death" then
			-- Calculate how much the thief got close to self flag and
			-- give rewards accordingly.
			local map_size = ctf_map.current_map.size
			local map_size_scalar = math.sqrt(map_size.x * map_size.z)
			local self_flag = ctf_map.current_map.teams[team].flag_pos
			local dist_to_self_flag = vector.distance(self_flag, drop_point)
			-- If it's sooo close to self flag, give 3/4 of capture reward
			if dist_to_self_flag < map_size_scalar / 20 then
				return math.ceil(capture_reward * 3 / 4)
			end
			-- If it's very very far from self flag, give only 1/12
			if dist_to_self_flag > map_size_scalar / 20 then
				return math.ceil(capture_reward / 12)
			end
			-- Here we make it into 5 parts. If the thief
			-- go so close to our(only 20% away) flag, we give 1/2 of score.
			-- If they were too far away(80% away), we give 1/5 score.
			-- If somewhere in between, we give 1/3 score.
			if dist_to_self_flag < 1 * map_size_scalar / 5 then
				return math.ceil(capture_reward / 2)
			elseif dist_to_self_flag > 1 * map_size_scalar / 5 then
				return math.ceil(capture_reward / 5)
			else
				return math.ceil(capture_reward / 3)
			end
		else
			-- If the reason is timeout, then give 1/3 of the cap reward
			return capture_reward / 3
		end
	end

	local damage_group_textures = {
		grenade = "grenades_frag.png",
		knockback_grenade = "ctf_mode_nade_fight_knockback_grenade.png",
		black_hole_grenade = "ctf_mode_nade_fight_black_hole_grenade.png",
		damage_cobble = "ctf_map_damage_cobble.png",
		damage_glass = "default_glass.png^[colorize:#B00000:180^default_glass_detail.png",
		landmine = "ctf_landmine_landmine.png",
		spike = "ctf_map_spike.png",
	}

	local function get_weapon_image(hitter, tool_capabilities)
		local image

		for group, texture in pairs(damage_group_textures) do
			if tool_capabilities.damage_groups[group] then
				image = texture
				break
			end
		end

		if not image then
			image = hitter:get_wielded_item():get_definition().inventory_image
		end

		if image == "" then
			image = "ctf_kill_list_punch.png"
		end

		if tool_capabilities.damage_groups.ranged then
			image = image .. "^[transformFX"
		elseif tool_capabilities.damage_groups.poison_grenade then
			image = "grenades_smoke_grenade.png^[multiply:#00ff00"
		end

		return image
	end

	local function get_suicide_image(reason)
		local image = "ctf_modebase_skull.png"

		if reason.type == "node_damage" then
			local node = reason.node
			if node:find("lava") then
				return "default_lava.png"
			end

			local node_def = core.registered_nodes[node]
			if node_def then
				local inv_image = node_def.inventory_image
				if inv_image and inv_image ~= "" then
					image = inv_image
				elseif node_def.tiles and node_def.tiles[1] then
					local tiles1 = node_def.tiles[1]
					if type(tiles1) == "string" then
						image = tiles1
					elseif tiles1.name and tiles1.name ~= "" then
						if tiles1.animation then
							local h = tiles1.animation.aspect_h or 16
							return tiles1.name .. "^[verticalframe:" .. h .. ":1"
						end
						image = tiles1.name
					end
				end
			end
		elseif reason.type == "drown" then
			image = "bubble.png"
		elseif reason.type == "fall" then
			image = "ctf_kill_list_falling_man.png"
		end

		return image
	end

	local function tp_player_near_flag(player)
		local tname = ctf_teams.get(player)
		if not tname then
			return
		end

		local flag_pos = ctf_map.current_map.teams[tname].flag_pos

		-- Generate random offset
		local random_off = {
			x = math.random(-1, 1),
			y = 0,
			z = math.random(-1, 1),
		}

		-- Avoid zero offset
		if random_off.x == 0 and random_off.z == 0 then
			random_off.x = 1 -- Shift along X if both are zero
		end

		local pos = vector.add(flag_pos, random_off)

		local rotation_y = vector.dir_to_rotation(
			vector.direction(
				pos,
				ctf_map.current_map.teams[tname].look_pos
					or ctf_map.current_map.flag_center
			)
		).y

		local function apply()
			player:set_pos(pos)
			player:set_look_vertical(0)
			player:set_look_horizontal(rotation_y)
		end

		apply()
		core.after(0.1, function() -- TODO: remove after respawn bug is fixed
			if player:is_player() then
				apply()
			end
		end)

		return true
	end

	local function celebrate_team(teamname)
		for _, player in ipairs(core.get_connected_players()) do
			local pname = player:get_player_name()
			local pteam = ctf_teams.get(pname)

			local sound_volume = (
				tonumber(ctf_settings.get(player, "ctf_modebase:flag_sound_volume"))
				or 10.0
			) / 10

			if pteam == teamname then
				core.sound_play("ctf_modebase_trumpet_positive", {
					to_player = pname,
					gain = sound_volume,
					pitch = 1.0,
				}, true)
			else
				core.sound_play("ctf_modebase_trumpet_negative", {
					to_player = pname,
					gain = sound_volume,
					pitch = 1.0,
				}, true)
			end
		end
	end

	local function drop_flag(teamname)
		for _, player in ipairs(core.get_connected_players()) do
			local pname = player:get_player_name()
			local pteam = ctf_teams.get(pname)

			if pteam then
				if pteam == teamname then
					core.sound_play("ctf_modebase_drop_flag_negative", {
						to_player = pname,
						gain = 0.2,
						pitch = 1.0,
					}, true)
				else
					core.sound_play("ctf_modebase_drop_flag_positive", {
						to_player = pname,
						gain = 0.2,
						pitch = 1.0,
					}, true)
				end
			end
		end
	end

	local function end_combat_mode(player, reason, killer, weapon_image)
		local comment = nil

		if reason == "combatlog" then
			killer, weapon_image = ctf_combat_mode.get_last_hitter(player)
			if killer then
				comment = " (Combat Log)"
				recent_rankings.add(player, { deaths = 1 }, true)
			end
		else
			if reason ~= "punch" or killer == player then
				if ctf_teams.get(player) then
					if reason == "punch" then
						ctf_kill_list.add(player, player, weapon_image)
					else
						ctf_kill_list.add("", player, get_suicide_image(reason))
					end
				end

				killer, weapon_image = ctf_combat_mode.get_last_hitter(player)
				comment = " (Suicide)"
			end
			recent_rankings.add(player, { deaths = 1 }, true)
		end

		if killer then
			local killscore = calculate_killscore(player, killer)

			local rewards = { kills = 1, score = killscore }
			local bounty = ctf_modebase.bounties.claim(player, killer)

			if bounty then
				for name, amount in pairs(bounty) do
					rewards[name] = (rewards[name] or 0) + amount
				end
			end

			recent_rankings.add(killer, rewards)

			if ctf_teams.get(killer) then
				ctf_kill_list.add(killer, player, weapon_image, comment)
			end

			-- share kill score with other hitters
			local hitters = ctf_combat_mode.get_other_hitters(player, killer)
			for _, pname in ipairs(hitters) do
				recent_rankings.add(
					pname,
					{ kill_assists = 1, score = math.ceil(killscore / #hitters) }
				)
				local healers = ctf_combat_mode.get_healers(pname)
				for _, healer in ipairs(healers) do
					recent_rankings.add(
						healer,
						{ score = math.ceil(killscore / #hitters / #healers / 2) }
					)
				end
			end

			-- share kill score with healers
			-- here we give the direct healers a share, and other
			-- healers(healers of healers) up to some depth also some score
			--
			-- The computation method: For instance mazes and shangul heal ANAND
			-- who in turn has healed savilli and savilli has got a kill now.
			-- There are a total of 16 + 8 + 8 = 32 parts now. ANAND gets
			-- 16/32(=1/2) killscore while mazes and shangul each get 8/32(=1/4) of it.
			-- Now imagining if there is also Kat healing mazes, we'll have
			-- 16 + 8 + 8 + 4 = 36 parts. Kat gets 4/36 of it, ANAND 16/36 and so on.
			-- TODO: in future, calculate max_depth in a way that all healers
			-- will get a score as long as their reward is >= 1.0
			--
			-- -- Farooq fkz at riseup dot net
			local max_depth = 3
			local healers, all_parts = ctf_combat_mode.get_all_healers(killer, max_depth)
			for healer, part in pairs(healers) do
				local healer_reward = math.ceil(killscore * part / all_parts)
				recent_rankings.add(healer, { score = healer_reward }, false)
			end

			if ctf_combat_mode.is_only_hitter(killer, player) then
				ctf_combat_mode.set_kill_time(killer, 5)
			end
		end

		ctf_combat_mode.end_combat(player)
	end

	local function can_punchplayer(player, hitter)
		if not ctf_modebase.match_started then
			return false, S("The match hasn't started yet!")
		end

		local pname, hname = player:get_player_name(), hitter:get_player_name()
		local pteam, hteam = ctf_teams.get(player), ctf_teams.get(hitter)

		if not ctf_modebase.remove_respawn_immunity(hitter) then
			return false, S("You can't attack while immune")
		end

		if not pteam then
			return false, S("@1 is not in a team!", pname)
		end

		if not hteam then
			return false, S("You are not in a team!")
		end

		if pteam == hteam and pname ~= hname then
			return false, S("@1 is on your team!", pname)
		end

		return true
	end

	local item_levels = {
		"wood",
		"stone",
		"bronze",
		"steel",
		"mese",
		"diamond",
	}

	local delete_queue = {}
	local team_switch_after_capture = false
	local streak_bonus_received = {}

	return {
		on_new_match = function()
			team_list = {}
			for tname in pairs(ctf_map.current_map.teams) do
				table.insert(team_list, tname)
			end
			teams_left = #team_list
			many_teams = #team_list > 2

			-- Detach all players
			for _, player in ipairs(core.get_connected_players()) do
				if player:get_attach() then
					player:set_detach()
					core.log("action", player:get_player_name() .. " detached")
				end
			end

			if #delete_queue > 0 and delete_queue._map ~= ctf_map.current_map.dirname then
				local p1, p2 = unpack(delete_queue)

				local ignore_objects = {
					"hpbar:entity",
					"wield3d:entity",
					"playertag:tag",
					"server_cosmetics:hat",
				}

				for _, obj in pairs(core.get_objects_in_area(p1, p2)) do
					if not obj:is_player() then
						local luaent = obj:get_luaentity()

						if
							luaent
							and table.indexof(ignore_objects, luaent.name) == -1
						then
							obj:remove()
						end
					end
				end

				core.delete_area(p1, p2)

				delete_queue = {}
			end

			-- Place treasures
			local tr = ctf_modebase:get_current_mode().treasures or {}

			local treasurefy_func
			local no_treasures = true
			-- If the treasures list is empty, chests will not be placed
			if next(tr) then
				local map_treasures = table.copy(tr)

				for k, v in
					pairs(
						ctf_map.treasure.treasure_from_string(
							ctf_map.current_map.treasures
						)
					)
				do
					map_treasures[k] = v
				end
				treasurefy_func = function(inv)
					ctf_map.treasure.treasurefy_node(inv, map_treasures)
				end
				no_treasures = false
			end

			ctf_map.prepare_map_nodes(
				ctf_map.current_map,
				treasurefy_func,
				no_treasures,
				ctf_modebase:get_current_mode().team_chest_items or {},
				ctf_modebase:get_current_mode().blacklisted_nodes or {}
			)

			if loading_screen_time then
				local total_time = (core.get_us_time() - loading_screen_time) / 1e6

				core.after(math.abs(LOADING_SCREEN_TARGET_TIME - total_time), function()
					hud:clear_all()
					set_playertags_state(PLAYERTAGS_ON)

					for _, player in ipairs(core.get_connected_players()) do
						core.close_formspec(
							player:get_player_name(),
							"ctf_modebase:summary"
						)
					end
				end)
			end
		end,
		on_match_end = function()
			recent_rankings.on_match_end()

			if ctf_map.current_map then
				-- Queue deletion for after the players have left
				delete_queue = {
					ctf_map.current_map.pos1,
					ctf_map.current_map.pos2,
					_map = ctf_map.current_map.dirname,
				}
			end
			streak_bonus_received = {}
		end,
		team_allocator = function(player)
			player = PlayerName(player)

			local team_scores = recent_rankings.teams()

			local best_kd = nil
			local worst_kd = nil
			local best_players = nil
			local worst_players = nil
			local total_players = 0

			for _, team in ipairs(team_list) do
				local players_count = ctf_teams.online_players[team].count
				local players = ctf_teams.online_players[team].players

				local bk = 0
				local bd = 1

				for name in pairs(players) do
					local rank = rankings:get(name)

					if rank then
						if bk <= (rank.kills or 0) then
							bk = rank.kills or 0
							bd = rank.deaths or 0
						end
					end
				end

				total_players = total_players + players_count

				local kd = bk / bd
				local match_kd = 0
				local tk = 0
				if team_scores[team] then
					if (team_scores[team].score or 0) >= 50 then
						tk = team_scores[team].kills or 0

						kd = math.max(
							kd,
							(team_scores[team].kills or bk)
								/ (team_scores[team].deaths or bd)
						)
					end

					match_kd = (team_scores[team].kills or 0)
						/ (team_scores[team].deaths or 1)
				end

				if not best_kd or match_kd > best_kd.a then
					best_kd = { s = kd, a = match_kd, t = team, kills = tk }
				end

				if not worst_kd or match_kd < worst_kd.a then
					worst_kd = { s = kd, a = match_kd, t = team, kills = tk }
				end

				if not best_players or players_count > best_players.s then
					best_players = { s = players_count, t = team }
				end

				if not worst_players or players_count < worst_players.s then
					worst_players = { s = players_count, t = team }
				end
			end

			if worst_players.s == 0 then
				return worst_players.t
			end

			local kd_diff = best_kd.s - worst_kd.s
			local actual_kd_diff = best_kd.a - worst_kd.a
			local players_diff = best_players.s - worst_players.s

			local rem_team = ctf_teams.get(player)
			local player_rankings = recent_rankings.get(player) --[pteam.."_score"]

			if ctf_core.testing.testing then
				if
					not rem_team
					or math.max(
							player_rankings[rem_team .. "_kills"] or 0,
							player_rankings[rem_team .. "_deaths"] or 0
						)
						<= 6
				then
					player_rankings = rankings:get(player) or {}
				else
					player_rankings.kills = player_rankings[rem_team .. "_kills"] or 0
					player_rankings.deaths = player_rankings[rem_team .. "_deaths"] or 1
				end
			else
				player_rankings = {}
			end

			local one_third = math.ceil(0.34 * total_players)
			-- local one_fifth     = math.ceil(0.2 * total_players)

			-- Allocate player to remembered team unless teams are imbalanced
			if
				rem_team
				and not ctf_modebase.flag_captured[rem_team]
				and (worst_kd.kills <= total_players or actual_kd_diff <= 0.8)
				and players_diff <= one_third
			then
				return rem_team
			end

			local pkd = (player_rankings.kills or 0) / (player_rankings.deaths or 1)
			local success, result = pcall(
				ctf_core.testing.test,
				pkd,
				kd_diff,
				actual_kd_diff,
				players_diff,
				best_kd,
				worst_kd,
				total_players,
				worst_players,
				best_players
			)

			if not success then
				core.log("error", result)
				result = false
			end

			-- [1]
			-- Allocate player to the worst team if it's losing by more than 0.4KD, as long as the amount of-
			-- players on the winning team isn't outnumbered by more than 1/5 the total players playing
			-- TODO: extra logic

			-- [2]
			-- Otherwise allocates the player to the team with the least amount of players,
			-- or the worst team if all teams have an equal amount of players
			if players_diff == 0 or result then
				return worst_kd.t
			else
				return worst_players.t
			end
		end,
		--- How much does an item values in score, when you put
		--- it in teamchest? Currently, it is used when someone dies
		--- and a teammate puts it back in teamchest. Also it is possible
		--- for modes to override these values.
		---
		--- in the chest. --Farooq
		--- @param itemname string
		--- @param teamchest_pos Vec3
		--- @return number
		get_item_value = function(itemname, teamchest_pos)
			-- teamchest_pos is passed
			-- here for future use. For instanace if we wanted to calculate value
			-- of an item depending on how many of the same item already exists in
			local value = default_item_value[itemname]
			return value or 0
		end,
		can_take_flag = function(player, teamname)
			if not ctf_modebase.match_started then
				tp_player_near_flag(player)

				return S("You can't take the enemy flag during build time!")
			end
		end,
		calculate_capture_reward = calculate_capture_reward,
		calculate_killscore = calculate_killscore,
		on_flag_take = function(player, teamname)
			local pname = player:get_player_name()
			local pteam = ctf_teams.get(player)
			local tcolor = ctf_teams.team[pteam].color

			ctf_modebase.remove_immunity(player)
			playertag.set(player, playertag.TYPE_BUILTIN, tcolor)

			local text = " has taken the flag"
			local flag_or_flags = " flag!"
			local teamnames_readable = HumanReadable(teamname)
			if many_teams then
				text = " has taken " .. teamnames_readable .. "'s flag"
				flag_or_flags = " flags!"
			end

			flag_event_notify(
				pname,
				pteam,
				teamname,
				{ text = "You have taken the " .. teamnames_readable .. flag_or_flags },
				{
					text = "Your teammate "
						.. pname
						.. " has taken the "
						.. teamnames_readable
						.. flag_or_flags,
				},
				{ text = pname .. " has taken your flag!", color = "warning" },
				{ text = pname .. text, color = "light" }
			)

			core.chat_send_all(
				core.colorize(tcolor, pname) .. core.colorize(FLAG_MESSAGE_COLOR, text)
			)
			ctf_modebase.announce(
				string.format("Player %s (team %s)%s", pname, pteam, text)
			)

			celebrate_team(ctf_teams.get(pname))
			recent_rankings.add(pname, {
				flag_attempts = 1,
			}, false)
			ctf_modebase.flag_huds.track_capturer(pname, FLAG_CAPTURE_TIMER)
		end,
		on_flag_drop = function(player, teamnames, pteam)
			local pname = player:get_player_name()
			local tcolor = pteam and ctf_teams.team[pteam].color or "#FFF"

			local text = " has dropped the flag"
			local teamnames_notify = "Your teammate " .. pname .. text
			if many_teams then
				text = " has dropped the flag of team(s) " .. HumanReadable(teamnames)
				teamnames_notify = "Your teammate " .. pname .. text
			end

			flag_event_notify(
				pname,
				pteam,
				teamnames,
				nil,
				{ text = teamnames_notify, color = "light" },
				{ text = pname .. " has dropped your flag!", color = "success" },
				{ text = pname .. text, color = "light" }
			)

			core.chat_send_all(
				core.colorize(tcolor, pname) .. core.colorize(FLAG_MESSAGE_COLOR, text)
			)
			recent_rankings.add(pname, {
				score = calculate_attempt_reward(
					pteam,
					player:get_pos(),
					"death",
					teamnames
				),
			}, false)
			ctf_modebase.announce(
				string.format("Player %s (team %s)%s", pname, pteam, text)
			)

			ctf_modebase.flag_huds.untrack_capturer(pname)

			playertag.set(player, playertag.TYPE_ENTITY)

			if player.set_observers then
				update_playertags()
			end

			drop_flag(pteam)
		end,
		on_flag_capture = function(player, teamnames)
			local pname = player:get_player_name()
			local pteam = ctf_teams.get(pname)
			if not pteam then
				core.log("error", "Someone is capping a flag but is not a teammember :/")
			end
			local tcolor = ctf_teams.team[pteam].color

			playertag.set(player, playertag.TYPE_ENTITY)

			if player.set_observers then
				update_playertags()
			end

			celebrate_team(pteam)

			ctf_modebase.flag_huds.untrack_capturer(pname)

			local team_scores = recent_rankings.teams()
			local capture_reward = calculate_capture_reward(pteam, teamnames)

			local text = S(
				" has captured the flag in @1 and got @2 points!",
				ctf_map.get_duration(),
				capture_reward
			)
			local teamnames_readable = HumanReadable(teamnames)
			local flag_or_flags = S("flag")
			if many_teams then
				text = S(
					" has captured the flag of team(s) @1 in @2 and got @3 points!",
					teamnames_readable,
					ctf_map.get_duration(),
					capture_reward
				)
				flag_or_flags = S("flags")
			end

			flag_event_notify(pname, pteam, teamnames, {
				text = S("You have captured: @1 @2!", teamnames_readable, flag_or_flags),
				color = "success",
			}, {
				text = S(
					"Your teammate @1 has captured: @2 @3!",
					pname,
					teamnames_readable,
					flag_or_flags
				),
				color = "success",
			}, { text = S(" has captured your flag!"), color = "warning" }, {
				text = S(" has captured: @1 @2!", teamnames_readable, flag_or_flags),
				color = "light",
			})

			core.chat_send_all(
				core.colorize(tcolor, pname) .. core.colorize(FLAG_MESSAGE_COLOR, text)
			)

			ctf_modebase.announce(S("Player @1 (team @2)@3", pname, pteam, text))

			local team_score = team_scores[pteam].score
			for teammate in pairs(ctf_teams.online_players[pteam].players) do
				if teammate ~= pname then
					local teammate_value = (
						recent_rankings.get(teammate)[pteam .. "_score"] or 0
					) / (team_score or 1)
					local victory_bonus = math.max(
						5,
						math.min(capture_reward / 2, capture_reward * teammate_value)
					)
					recent_rankings.add(teammate, { score = victory_bonus }, true)
				end
			end

			local max_depth = 4
			local healers, all_parts = ctf_combat_mode.get_all_healers(pname, max_depth)
			for healer, part in pairs(healers) do
				local healer_reward = math.ceil(capture_reward * part / all_parts)
				recent_rankings.add(healer, { score = healer_reward }, false)
			end

			recent_rankings.add(
				pname,
				{ score = capture_reward, flag_captures = #teamnames }
			)

			local streak_idx = ctf_modebase.player_on_flag_attempt_streak[pname]
			if streak_idx then
				local streak_bonus
				if streak_bonus_received[pname] then
					streak_bonus = math.floor(
						math.abs(streak_bonus_received[pname] - streak_idx * 20)
					)
				else
					streak_bonus = math.floor(streak_idx * 20)
				end
				streak_bonus_received[pname] = streak_bonus

				hud_events.new(pname, {
					text = S("Streak Bonus +@1", streak_bonus),
					color = "info",
					quick = true,
				})

				recent_rankings.add(pname, { score = streak_bonus }, true)
			end

			teams_left = teams_left - #teamnames

			if teams_left <= 1 then
				local capture_text = "Player @1 captured"
				if many_teams then
					capture_text = "Player @1 captured the last flag"
				end
				capture_text = S(capture_text, pname)
				-- there might be some unclaimed player bounties, here we return
				-- the points to their contributors
				for _, bounty in
					pairs(ctf_modebase.bounties.get_unclaimed_player_bounties())
				do
					for bounty_donator, bounty_amount in pairs(bounty.contributors) do
						recent_rankings.add(
							bounty_donator,
							{ score = bounty_amount },
							true
						)
					end
				end

				ctf_modebase.bounties.clear_player_bounties()

				ctf_modebase.summary.set_winner(
					string.format(capture_text, core.colorize(tcolor, pname))
				)

				local win_text = S("@1 Team Wins!", HumanReadable(pteam))

				core.chat_send_all(core.colorize(pteam, win_text))

				local match_rankings, special_rankings, rank_values, formdef =
					ctf_modebase.summary.get()
				formdef.title = win_text

				for _, pn in ipairs(ctf_teams.get_all_team_players()) do
					ctf_modebase.summary.show_gui(
						pn,
						match_rankings,
						special_rankings,
						rank_values,
						formdef
					)
				end

				ctf_modebase.start_new_match(5)
			else
				for _, lost_team in ipairs(teamnames) do
					table.remove(team_list, table.indexof(team_list, lost_team))

					for lost_player in pairs(ctf_teams.online_players[lost_team].players) do
						team_switch_after_capture = true
						ctf_teams.allocate_player(lost_player)
						team_switch_after_capture = false
					end
				end
			end
		end,
		on_allocplayer = function(player, new_team)
			player:set_hp(player:get_properties().hp_max)

			if not team_switch_after_capture then
				ctf_modebase.update_wear.cancel_player_updates(player)

				ctf_modebase.player.remove_bound_items(player)
				ctf_modebase.player.give_initial_stuff(player)
			end

			local tcolor = ctf_teams.team[new_team].color
			player:hud_set_hotbar_image("gui_hotbar.png^[colorize:" .. tcolor .. ":128")
			player:hud_set_hotbar_selected_image(
				"gui_hotbar_selected.png^[multiply:" .. tcolor
			)

			player_api.set_texture(player, 1, ctf_cosmetics.get_skin(player))

			recent_rankings.set_team(player, new_team)

			playertag.set(player, playertag.TYPE_ENTITY)

			if player.set_observers then
				update_playertags()
			end

			tp_player_near_flag(player)
		end,
		on_leaveplayer = function(player)
			if not ctf_modebase.match_started then
				ctf_combat_mode.end_combat(player)
				return
			end

			local pname = player:get_player_name()

			-- should be no_hud to avoid a race
			end_combat_mode(pname, "combatlog")

			recent_rankings.on_leaveplayer(pname)
		end,
		on_dieplayer = function(player, reason)
			if not ctf_modebase.match_started then
				return
			end

			-- punch is handled in on_punchplayer
			if reason.type ~= "punch" then
				end_combat_mode(player:get_player_name(), reason)
			end

			if ctf_teams.get(player) then
				ctf_modebase.prepare_respawn_delay(player)
			end
		end,
		on_respawnplayer = function(player)
			tp_player_near_flag(player)
		end,
		player_is_pro = function(pname)
			local rank = rankings:get(pname)
			if is_pro(core.get_player_by_name(pname), rank) then
				return true
			end
		end,
		get_chest_access = function(pname)
			local rank = rankings:get(pname)

			local deny_pro = S("You need to have more than 1.4 kills per death, ")
				.. S("5 captures, and at least 8,000 score to access the pro section.")
			if rank then
				local captures_needed = math.max(0, 5 - (rank.flag_captures or 0))
				local score_needed = math.max(math.max(0, 8000 - (rank.score or 0)))
				local current_kd = math.floor((rank.kills or 0) / (rank.deaths or 1) * 10)
				current_kd = current_kd / 10
				deny_pro = deny_pro
					.. S(
						" You still need @1 captures, @2 score and your KD is @3.",
						captures_needed,
						score_needed,
						current_kd
					)

				if is_pro(core.get_player_by_name(pname), rank) then
					return true, true
				elseif (rank.score or 0) >= 10 then
					return true, deny_pro
				end
			end

			return "You need at least 10 score to access this chest", deny_pro
		end,
		can_punchplayer = can_punchplayer,
		on_punchplayer = function(player, hitter, damage, _, tool_capabilities)
			if not hitter:is_player() or player:get_hp() <= 0 then
				return false
			end

			local allowed, message = can_punchplayer(player, hitter)

			if not allowed then
				return false, message
			end

			local weapon_image = get_weapon_image(hitter, tool_capabilities)

			if player:get_hp() <= damage then
				end_combat_mode(
					player:get_player_name(),
					"punch",
					hitter:get_player_name(),
					weapon_image
				)

				-- Turn player's camera to face the killer
				local dir = vector.direction(player:get_pos(), hitter:get_pos())
				player:set_look_horizontal(core.dir_to_yaw(dir))
			elseif player:get_player_name() ~= hitter:get_player_name() then
				ctf_combat_mode.add_hitter(player, hitter, weapon_image, 15)
			end

			return damage
		end,
		on_healplayer = function(player, patient, amount)
			if not ctf_modebase.match_started then
				return "The match hasn't started yet!"
			end

			local score = nil

			if ctf_combat_mode.in_combat(patient) then
				score = 1
			end

			ctf_combat_mode.add_healer(patient, player, 60)
			recent_rankings.add(player, { hp_healed = amount, score = score }, true)
		end,
		initial_stuff_item_levels = {
			pick = function(item)
				local match = item:get_name():match("default:pick_(%a+)")

				if match then
					return table.indexof(item_levels, match)
				end
			end,
			axe = function(item)
				local match = item:get_name():match("default:axe_(%a+)")

				if match then
					return table.indexof(item_levels, match)
				end
			end,
			shovel = function(item)
				local match = item:get_name():match("default:shovel_(%a+)")

				if match then
					return table.indexof(item_levels, match)
				end
			end,
			sword = function(item)
				local mod, match = item:get_name():match("([^:]+):sword_(%a+)")

				if mod and (mod == "default" or mod == "ctf_melee") and match then
					return table.indexof(item_levels, match)
				end
			end,
		},
	}
end
