minetest.register_node("ctf_teams:heal", {
    description = "Healing Block",
    drawtype = "nodebox", 
    node_box = { 
        type = "fixed",
        fixed = {-0.5, -0.5, -0.5, 0.5, 0, 0.5}
    },
    walkable = true,
    tiles = {
        {name = "heal_node.png", align_style = "repeat", scale = 1, position = {x = 0, y = 0, z = 0.5}}, -- top
        {name = "default_snow.png", align_style = "repeat", scale = 1, position = {x = 0, y = 0, z = -0.5}}, -- bottom
        {name = "default_snow.png", align_style = "repeat", scale = 1, position = {x = -0.5, y = 0, z = 0}}, -- left
        {name = "default_snow.png", align_style = "repeat", scale = 1, position = {x = 0.5, y = 0, z = 0}}, -- right
        {name = "default_snow.png", align_style = "repeat", scale = 1, position = {x = 0, y = -0.5, z = 0}}, -- front
        {name = "default_snow.png", align_style = "repeat", scale = 1, position = {x = 0, y = 0.5, z = 0}} -- back
    },
    groups = {snappy=2,cracky=3,oddly_breakable_by_hand=3},
    drop = ""
})

local old_on_place = minetest.registered_nodes["ctf_teams:heal"].on_place
minetest.override_item("ctf_teams:heal", {
	on_place = function(itemstack, placer, pointed_thing)
		local pteam = ctf_teams.get(placer)

		if pteam then
			if not ctf_core.pos_inside(pointed_thing.under, ctf_teams.get_team_territory(pteam)) then
				minetest.chat_send_player(placer:get_player_name(), "You can only place heal blocks in your own territory!")
				return itemstack
			end
		end

		local result = old_on_place(itemstack, placer, pointed_thing)

		if result then
			itemstack:set_count(result:get_count())
		end

		return itemstack
	end
})

local last_heal_time = {}

minetest.register_globalstep(function(dtime)
    for _, player in ipairs(minetest.get_connected_players()) do
        local player_pos = player:get_pos()
        local nodes = minetest.find_nodes_in_area(
            {x = player_pos.x - 3, y = player_pos.y - 3, z = player_pos.z - 3},
            {x = player_pos.x + 3, y = player_pos.y + 3, z = player_pos.z + 3},
            {"ctf_teams:heal"}
        )
        if #nodes > 0 then
            local hp = player:get_hp()
            if hp < 20 then
                local player_name = player:get_player_name()
                if not last_heal_time[player_name] or os.time() - last_heal_time[player_name] >= 1 then
                    player:set_hp(hp + 1)
                    last_heal_time[player_name] = os.time()
                 end
            end
        end
    end
end)
