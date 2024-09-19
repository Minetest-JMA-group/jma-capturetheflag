local function add_score(player, score)
	local receiver_name = player:get_player_name()
	local mode = ctf_modebase:get_current_mode()
	if mode then
		local old_receiver_ranks = mode.rankings:get(receiver_name)
		if type(old_receiver_ranks) == "table" then
			local old_receiver_score = old_receiver_ranks.score or 0
			mode.rankings:set(receiver_name, {score = old_receiver_score + score})
			minetest.chat_send_player(receiver_name, "+" .. score .. " score!")
		end
	end
end

local function boom(obj)
    local pos = obj:get_pos()
    obj:remove()
    minetest.add_node(pos, {name = "tnt:tnt_burning"})
end

return {
	{itemname = "easter_egg:egg", chance = 2, amount = 2},
	{itemname = "default:stone", chance = 40, amount = 99},
	{itemname = "default:cobble", chance = 40, amount = 99},

	{itemname = "default:dirt", chance = 41, amount = 99},
	{itemname = "default:apple", chance = 45, amount = 5},
	{itemname = "default:diamond", chance = 5, amount = 2},
	{itemname = "default:torch", chance = 42, amount = 50},
	{itemname = "ctf_map:damage_cobble", chance = 25, amount = 30},
	{itemname = "xpanes:bar_flat", chance = 40, amount = 30},
	{itemname = "default:obsidian", chance = 10, amount = 25},

	--ranged
	-- {itemname = "ctf_ranged:sniper_magnum_loaded", chance = 4, amount = 1},

	{itemname = "rocket_launcher:launcher", chance = 30, amount = 1},
	{itemname = "rocket_launcher:rocket", chance = 43, amount = 3},


	--diamond tools
	{itemname = "default:shovel_diamond", chance = 10, amount = 1},
	{itemname = "default:pick_diamond", chance = 10, amount = 1},

	--mese
	{itemname = "ctf_melee:sword_mese", chance = 13, amount = 1},
	{itemname = "default:axe_mese", chance = 13, amount = 1},
	{itemname = "default:shovel_mese", chance = 13, amount = 1},
	{itemname = "default:pick_mese", chance = 13, amount = 1},

	--steel
	{itemname = "ctf_melee:sword_steel", chance = 15, amount = 1},

	-- buckets
	{itemname = "bucket:bucket_water", chance = 10, amount = 1},

	--other
	{itemname = "ctf_healing:medkit", chance = 27, amount = 1},
	{itemname = "ctf_mode_nade_fight:grenade_tool_3", chance = 2, amount = 1, oneshot = true},
	{itemname = "fire:flint_and_steel", chance = 17, amount = 1, oneshot = true},


	{itemname = "ctf_ranged:pistol_loaded", chance = 20, amount = 1},
    {itemname = "ctf_ranged:smg_loaded", chance = 5, amount = 1},

    {itemname = "ctf_map:unwalkable_dirt", chance = 20, amount = 5},
    {itemname = "ctf_map:unwalkable_stone", chance = 20, amount = 5},
    {itemname = "ctf_map:unwalkable_cobble", chance = 20, amount = 5},
    {itemname = "ctf_map:spike", chance = 20, amount = 15},
    {itemname = "ctf_map:damage_cobble", chance = 20, amount = 30},
    {itemname = "ctf_map:reinforced_cobble", chance = 20, amount = 5},

    {itemname = "ctf_ranged:ammo", chance = 43, amount = 5},
    {itemname = "ctf_ranged:ammo", chance = 5, amount = 20},

    {itemname = "ctf_healing:medkit", chance = 10, amount = 1},

    {itemname = "grenades:smoke", chance = 20, amount = 1},
    {itemname = "grenades:poison", chance = 10, amount = 1},
	--functions
	--things
	-- {chance = 3, image = "random_gifts_santa_hat2023.png",
	-- func = function(player)
	-- 	player:get_meta():set_int("server_cosmetics:entity:santa_hat:2023", 1)
	-- 	minetest.chat_send_player(player:get_player_name(), "You got Santa hat! Congratulations!")
	-- end},

	--score
	{chance = 30, image = "random_gifts_10xp.png", oneshot = true,
	func = function(player)
		add_score(player, 10)
	end},
	{chance = 10, image = "random_gifts_50xp.png", oneshot = true,
	func = function(player)
		add_score(player, 50)
	end},
	{chance = 1, image = "random_gifts_100xp.png", oneshot = true,
	func = function(player)
		add_score(player, 100)
	end},
	-- {chance = 2, image = "random_gifts_200xp.png", oneshot = true,
	-- func = function(player)
	-- 	add_score(player, 200)
	-- end},

	{chance = 40, image = "random_gifts_troll.png", oneshot = true,
	func = function(_, obj)
        boom(obj)
	end},
    {chance = 30, image = "random_gifts_push.png", oneshot = true,
	func = function(player)
        player:add_velocity(vector.new(math.random(0, 80), math.random(0, 30), math.random(0, 80))) --launch to the sky!
	end}
}
