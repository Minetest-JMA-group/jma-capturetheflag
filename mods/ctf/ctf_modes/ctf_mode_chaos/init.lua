ctf_mode_chaos = {}
local rankings = ctf_rankings.init()
local recent_rankings = ctf_modebase.recent_rankings(rankings)
local features = ctf_modebase.features(rankings, recent_rankings)
local storage = core.get_mod_storage()

local old_bounty_reward_func = ctf_modebase.bounties.bounty_reward_func
local old_get_next_bounty = ctf_modebase.bounties.get_next_bounty

ctf_core.include_files("modifiers.lua")
ctf_mode_chaos.weapons_api = ctf_core.include_files("weapons_api.lua")
ctf_core.include_files("grenade_launcher.lua", "shotgun.lua",
	 "rocket_launcher.lua", "shield.lua", "concrete.lua", "bunny_sword.lua",
	"stamina_booster.lua")
ctf_core.include_files("rg_treasures.lua")

local STORAGE_KEY = "chaos_weekend_mode"

ctf_modebase.register_mode("chaos", {
	on_prevote = function()
		local today = tonumber(os.date("%w"))
		if storage:get_int(STORAGE_KEY) == 1 or today == 0 or today == 6 then
			return true
		end
		return false
	end,
	vote_label = core.colorize("orange", "(Test Phase)"),
	hp_regen = 4,
	crafts = {
		"ctf_mode_chaos:concrete",
		"ctf_mode_chaos:power_charge 16",
	},
	physics = { sneak_glitch = true, new_move = true },

	team_chest_items = {
		"default:cobble 99",
		"ctf_teams:door_steel 2",
		"ctf_mode_chaos:rocket 12",
		"ctf_healing:heal_block",
		"ctf_mode_chaos:power_charge 60",
		"ctf_mode_chaos:shield",
		"ctf_mode_chaos:concrete 30",
		"ctf_landmine:landmine 16"
	},
	rankings = rankings,
	recent_rankings = recent_rankings,
	summary_ranks = {
		_sort = "score",
		"score",
		"flag_captures",
		"flag_attempts",
		"kills",
		"kill_assists",
		"bounty_kills",
		"deaths",
	},
	build_timer = 20,

	is_bound_item = function(_, name)
		if
			name:match("ctf_mode_chaos:grenade_launcher_") or
			name == "ctf_mode_chaos:bunny_sword"
		then
			return true
		end
	end,
	stuff_provider = function(player)
		local current = ctf_mode_chaos.get_current_mode(player)
		return {
			"ctf_mode_chaos:grenade_launcher_" .. current,
			"ctf_mode_chaos:bunny_sword",
			"ctf_mode_chaos:power_charge 30",
		}
	end,
	initial_stuff_item_levels = features.initial_stuff_item_levels,
	on_mode_start = function()
		ctf_modebase.bounties.bounty_reward_func =
			ctf_modebase.bounty_algo.kd.bounty_reward_func
		ctf_modebase.bounties.get_next_bounty =
			ctf_modebase.bounty_algo.kd.get_next_bounty

		-- Fresh upgrades every time the mode is (re)started
		for _, player in ipairs(core.get_connected_players()) do
			ctf_mode_chaos.clear_player_state(player)
			ctf_mode_chaos.update_hud(player)
		end
	end,
	on_mode_end = function()
		ctf_modebase.bounties.bounty_reward_func = old_bounty_reward_func
		ctf_modebase.bounties.get_next_bounty = old_get_next_bounty

		for _, player in ipairs(core.get_connected_players()) do
			ctf_mode_chaos.remove_hud(player)
		end

		random_gifts.stop_spawn_timer()
	end,
	get_item_value = function()
		return 0
	end,
	get_player_label = features.get_player_label,
	get_player_nametag_color = features.get_player_nametag_color,
	get_player_nametag_bgcolor = features.get_player_nametag_bgcolor,
	get_ranking = features.get_ranking,
	get_recent_ranking = features.get_recent_ranking,
	on_new_match = function()
		-- Upgrades are match-scoped: fresh weapon for every match
		for _, player in ipairs(core.get_connected_players()) do
			ctf_mode_chaos.clear_player_state(player)
			ctf_mode_chaos.update_hud(player)
		end
		random_gifts.run_spawn_timer()
		core.chat_send_all(core.colorize("orange",
			"Chaos Mode is currently under development - bugs are to be expected.")
		)

		return features.on_new_match()
	end,
	on_match_end = function ()
		random_gifts.stop_spawn_timer()
		return features.on_match_end()
	end,
	team_allocator = features.team_allocator,
	on_allocplayer = function(player, new_team)
		local result = features.on_allocplayer(player, new_team)
		ctf_mode_chaos.update_hud(player)
		player:set_properties({ hp_max = 30 })
		player:set_hp(30)
		return result
	end,
	on_leaveplayer = features.on_leaveplayer,
	on_dieplayer = function(player, reason)
		local thing = ctf_mode_chaos.remove_random_upgrade(player)
		if thing then
			local pos = player:get_pos()

			if thing.item_name then
				core.add_item(pos, thing.item_name)
			end

			hud_events.new(player,
			"You’ve lost your " ..
				ctf_mode_chaos.get_display_name(thing.weapon, thing.key)
			)
		end
		ctf_mode_chaos.update_hud(player)
		ctf_mode_chaos.clear_all_global_effects(player)
		return features.on_dieplayer(player, reason)
	end,
	on_respawnplayer = function(player)
		local result = features.on_respawnplayer(player)
		ctf_mode_chaos.on_respawn(player)
		return result
	end,
	can_take_flag = features.can_take_flag,
	on_flag_take = features.on_flag_take,
	on_flag_drop = features.on_flag_drop,
	on_flag_capture = features.on_flag_capture,
	on_flag_rightclick = function() end,
	get_chest_access = features.get_chest_access,
	player_is_pro = features.player_is_pro,
	can_punchplayer = features.can_punchplayer,
	on_punchplayer = function(player, hitter, damage, unneeded, tool_capabilities, ...)
		local blocked = ctf_mode_chaos.block_shield_damage(player, damage)
		return features.on_punchplayer(
			player,
			hitter,
			damage - blocked,
			unneeded,
			tool_capabilities
		)
	end,
	on_healplayer = features.on_healplayer,
	calculate_knockback = function(
		player,
		hitter,
		time_from_last_punch,
		tool_capabilities,
		dir,
		distance,
		damage
	)
		if features.can_punchplayer(player, hitter) then
			return 2 * (tool_capabilities.damage_groups.knockback or 1)
		else
			return 0
		end
	end,
})

ctf_jma_elysium.register_on_join(function(player)
	ctf_mode_chaos.clear_player_state(player)
end)

core.register_chatcommand("wannachaos", {
	privs = { dev = true },
	func = function(name, param)
		local args = param:split(" ")
		local mode = args[1] or ""

		if mode == "on" then
			storage:set_int(STORAGE_KEY, 1)
			return true, "Every day mode"
		end
		if mode == "off" then
			storage:set_int(STORAGE_KEY, 0)
			return true, "Weekend mode"
		end

		return true, "Chaos mode is currently: "
			.. (storage:get_int(STORAGE_KEY) == 1 and "Every day" or "Weekend only") ..
			".\n" .. "Usage: /wannachaos [on|off]"
	end,
})
