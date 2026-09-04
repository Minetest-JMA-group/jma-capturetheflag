local function add_score(player, score)
	local receiver_name = player:get_player_name()
	local mode = ctf_modebase:get_current_mode()
	if mode then
		local old_receiver_ranks = mode.rankings:get(receiver_name)
		if type(old_receiver_ranks) == "table" then
			local old_receiver_score = old_receiver_ranks.score or 0
			mode.rankings:set(receiver_name, { score = old_receiver_score + score })
			hud_events.new(receiver_name, {
				text = "Score +" .. score,
				quick = true,
			})
		end
	end
end

local items = {
	{ itemname = "ctf_mode_chaos:power_charge",                    chance = 48, amount = 32 },
	{ itemname = "default:cobble",                                 chance = 40, amount = 99 },
	{ itemname = "default:dirt",                                   chance = 41, amount = 99 },
	{ itemname = "default:apple",                                  chance = 45, amount = 10 },
	{ itemname = "default:obsidian",                               chance = 10, amount = 15 },
	{ itemname = "ctf_mode_chaos:concrete",                        chance = 25, amount = 30 },

	{ itemname = "ctf_mode_chaos:rocket",                          chance = 39, amount = 16 },

	--diamond tools
	{ itemname = "default:shovel_diamond",                         chance = 25, amount = 1 },
	{ itemname = "default:pick_diamond",                           chance = 25, amount = 1 },
	{ itemname = "default:sword_diamond",                          chance = 4,  amount = 1 },

	-- buckets
	{ itemname = "bucket:bucket_water",                            chance = 10, amount = 1 },

	-- { itemname = "fire:flint_and_steel", chance = 17, amount = 1, oneshot = true },
	{ itemname = "ctf_ranged:assault_rifle_loaded",                chance = 5,  amount = 1 },
	{ itemname = "ctf_map:damage_cobble",                          chance = 20, amount = 30 },
	{ itemname = "ctf_map:damage_glass",                           chance = 20, amount = 30 },

	{ itemname = "ctf_ranged:ammo",                                chance = 40, amount = 16 },

	-- shared launcher modifiers (apply to the grenade launcher and the rocket
	-- launcher; using one opens a formspec to pick the weapon)
	{ itemname = "ctf_mode_chaos:charger",                         chance = 7,  amount = 1 },
	{ itemname = "ctf_mode_chaos:fast_reload",                     chance = 8,  amount = 1 },
	{ itemname = "ctf_mode_chaos:propellant",                      chance = 8,  amount = 1 },
	{ itemname = "ctf_mode_chaos:big_bang",                        chance = 7,  amount = 1 },
	-- { itemname = "ctf_mode_chaos:stabilizer",               chance = 7,  amount = 1 },
	{ itemname = "ctf_mode_chaos:mod_bouncy",                      chance = 5,  amount = 1 },
	{ itemname = "ctf_mode_chaos:mod_cluster",                     chance = 4,  amount = 1 },
	{ itemname = "ctf_mode_chaos:mod_sticky",                      chance = 4,  amount = 1 },

	-- standalone weapon modifiers
	{ itemname = "ctf_mode_chaos:mod_rocket_launcher_rain",        chance = 3,  amount = 1 },

	-- standalone weapons
	-- { itemname = "ctf_mode_chaos:shotgun", chance = 3, amount = 1 },
	{ itemname = "ctf_mode_chaos:rocket_launcher_rocket",          chance = 10, amount = 1 },
	{ itemname = "ctf_ranged:assault_rifle_loaded",                chance = 10, amount = 1 },

	-- Kb grenade modifiers
	{ itemname = "ctf_mode_chaos:mod_knockback_grenade_knockback", chance = 2,  amount = 1 },

	-- passive items
	{ itemname = "ctf_mode_chaos:stamina_booster",                 chance = 7,  amount = 1 },

	-- others
	{ itemname = "ctf_mode_chaos:shield",                          chance = 25,  amount = 1 },
	{ itemname = "ctf_mode_chaos:mod_shield_hardened",             chance = 15,  amount = 1 },

	--score
	{
		chance = 25,
		image = "random_gifts_10xp.png",
		func = function(player)
			add_score(player, 10)
		end,
	},
	{
		chance = 15,
		image = "random_gifts_50xp.png",
		func = function(player)
			add_score(player, 50)
		end,
	},
	{
		chance = 10,
		image = "random_gifts_100xp.png",
		func = function(player)
			add_score(player, 100)
		end,
	},

	{
		chance = 30,
		image = "random_gifts_push.png",
		func = function(player)
			player:add_velocity(
				vector.new(math.random(-30, 30), math.random(0, 30), math.random(-30, 30))
			) --launch to the sky!
			core.close_formspec(player:get_player_name(), "")
		end,
	},
}

random_gifts.set_items(items)
random_gifts.set_gift_count_range(4, 16)
