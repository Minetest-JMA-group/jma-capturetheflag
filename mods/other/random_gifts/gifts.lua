local function add_score(player, score)
	local receiver_name = player:get_player_name()
	local mode = ctf_modebase:get_current_mode()
	if type(mode) == "table" then
		local old_receiver_ranks = mode.rankings:get(receiver_name)
		local old_receiver_score = old_receiver_ranks.score or 0
		mode.rankings:set(receiver_name, {score = old_receiver_score + score})
		minetest.chat_send_player(receiver_name, "You got " .. score .. " scores!")
	end
end

local function boom(obj)
    local pos = obj:get_pos()
    obj:remove()
    minetest.add_node(pos, {name = "tnt:tnt_burning"})
    minetest.after(0.5, function()
        if random_gifts.entity_exists(obj) then
            tnt.boom(pos, {radius = math.random(2, 10)})
        end
    end)
end

random_gifts.list = {
	{itemname = "default:stone", chance = 40, amount = 50},
	{itemname = "default:dirt", chance = 41, amount = 50},
	{itemname = "default:apple", chance = 45, amount = 3},
	{itemname = "default:diamond", chance = 5, amount = 2},
	{itemname = "default:torch", chance = 42, amount = 50},
	{itemname = "ctf_map:damage_cobble", chance = 25, amount = 30},

	--ranged
	{itemname = "ctf_ranged:ammo", chance = 32, amount = 5},
	{itemname = "ctf_ranged:sniper_magnum_loaded", chance = 8, amount = 1, oneshot = true},
	{itemname = "ctf_ranged:shotgun_loaded", chance = 8, amount = 1, oneshot = true},

	--grenades
	{itemname = "throwable_snow:snowball", chance = 40, amount = 50},
	{itemname = "grenades:frag_sticky", chance = 7, amount = 5, oneshot = true},
	{itemname = "grenades:frag", chance = 10, amount = 10, oneshot = true},

	--diamond tools
	{itemname = "ctf_melee:sword_diamond", chance = 6, amount = 1},
	{itemname = "default:axe_diamond", chance = 6, amount = 1},
	{itemname = "default:shovel_diamond", chance = 7, amount = 1},
	{itemname = "default:pick_diamond", chance = 7, amount = 1},

	--mese
	{itemname = "ctf_melee:sword_mese", chance = 8, amount = 1},
	{itemname = "default:axe_mese", chance = 8, amount = 1},
	{itemname = "default:shovel_mese", chance = 10, amount = 1},
	{itemname = "default:pick_mese", chance = 10, amount = 1},

	--steel
	{itemname = "ctf_melee:sword_steel", chance = 15, amount = 1},
	{itemname = "default:axe_steel", chance = 17, amount = 1},
	{itemname = "default:shovel_steel", chance = 17, amount = 1},
	{itemname = "default:pick_steel", chance = 17, amount = 1},

	-- buckets
	{itemname = "bucket:bucket_lava", chance = 15, amount = 1},
	{itemname = "bucket:bucket_water", chance = 15, amount = 1},

	--other
	{itemname = "ctf_healing:medkit", chance = 27, amount = 1},
	{itemname = "ctf_mode_nade_fight:grenade_tool_3", chance = 2, amount = 1, oneshot = true},

	--functions
	--things
	{chance = 15, image = "random_gifts_santa_hat2023.png",
	func = function(player)
		player:get_meta():set_int("server_cosmetics:entity:santa_hat:2023", 1)
		minetest.chat_send_player(player:get_player_name(), "You got Santa hat! Congratulations!")
	end},

	--score
	{chance = 30, image = "random_gifts_10xp.png", oneshot = true,
	func = function(player)
		add_score(player, 10)
	end},
	{chance = 15, image = "random_gifts_50xp.png", oneshot = true,
	func = function(player)
		add_score(player, 50)
	end},
	{chance = 5, image = "random_gifts_100xp.png", oneshot = true,
	func = function(player)
		add_score(player, 100)
	end},
	{chance = 2, image = "random_gifts_200xp.png", oneshot = true,
	func = function(player)
		add_score(player, 200)
	end},
	{chance = 40, image = "random_gifts_troll.png", oneshot = true,
	func = function(_, obj)
        boom(obj)
	end},
    {chance = 40, image = "random_gifts_troll.png", oneshot = true,
	func = function(player)
        player:add_velocity(vector.new(0, 35, 0)) --launch to the sky!
	end},
	{chance = 35, image = "tnt_side.png", oneshot = true,
	func = function(_, obj)
        boom(obj)
	end},
}
