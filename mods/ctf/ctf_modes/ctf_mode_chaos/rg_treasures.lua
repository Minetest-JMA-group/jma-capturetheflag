local function add_score(player, score)
	local receiver_name = player:get_player_name()
	local mode = ctf_modebase:get_current_mode()
	if mode then
		local old_receiver_ranks = mode.rankings:get(receiver_name)
		if type(old_receiver_ranks) == "table" then
			local old_receiver_score = old_receiver_ranks.score or 0
			mode.rankings:set(receiver_name, { score = old_receiver_score + score })
			core.chat_send_player(receiver_name, "+" .. score .. " score!")
		end
	end
end

return {
	{ itemname = "ctf_mode_chaos:power_charge", chance = 48, amount = 10 },
	{ itemname = "default:cobble", chance = 40, amount = 99 },
	{ itemname = "default:dirt", chance = 41, amount = 99 },
	{ itemname = "default:apple", chance = 45, amount = 5 },
	{ itemname = "default:obsidian", chance = 10, amount = 25 },

	{ itemname = "rocket_launcher:launcher", chance = 30, amount = 1 },
	{ itemname = "rocket_launcher:rocket", chance = 43, amount = 3 },

	--diamond tools
	{ itemname = "default:shovel_diamond", chance = 10, amount = 1 },
	{ itemname = "default:pick_diamond", chance = 10, amount = 1 },

	-- buckets
	{ itemname = "bucket:bucket_water", chance = 10, amount = 1 },

	--other

	-- { itemname = "fire:flint_and_steel", chance = 17, amount = 1, oneshot = true },
	{ itemname = "ctf_ranged:assault_rifle_loaded", chance = 5, amount = 1 },
	{ itemname = "ctf_map:damage_cobble", chance = 20, amount = 30 },
	{ itemname = "ctf_map:damage_glass", chance = 20, amount = 30 },
	{ itemname = "ctf_map:reinforced_cobble", chance = 20, amount = 5 },

	{ itemname = "ctf_ranged:ammo", chance = 5, amount = 20 },

	--score
	{
		chance = 25,
		image = "random_gifts_10xp.png",
		oneshot = true,
		func = function(player)
			add_score(player, 10)
		end,
	},
	{
		chance = 5,
		image = "random_gifts_50xp.png",
		oneshot = true,
		func = function(player)
			add_score(player, 50)
		end,
	},
	{
		chance = 1,
		image = "random_gifts_100xp.png",
		oneshot = true,
		func = function(player)
			add_score(player, 100)
		end,
	},

	{
		chance = 30,
		image = "random_gifts_push.png",
		oneshot = true,
		func = function(player)
			player:add_velocity(
				vector.new(math.random(0, 80), math.random(0, 30), math.random(0, 80))
			) --launch to the sky!
		end,
	},
}
