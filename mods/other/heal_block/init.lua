-- Made by Maintainer_ (FoxLoveFire) 2024 
local last_heal_time = {}
minetest.register_node("heal_block:heal", {
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
    drop = "",
    on_place = function(itemstack, placer, pointed_thing)
        local pteam = ctf_teams.get(placer)
        if pteam then
            if not ctf_core.pos_inside(pointed_thing.under, ctf_teams.get_team_territory(pteam)) then
                minetest.chat_send_player(placer:get_player_name(), "You can only place heal blocks in your own territory!")
                return itemstack
            end
        end
        minetest.item_place(itemstack, placer, pointed_thing)
        return itemstack
    end,
    on_construct = function(pos)
        minetest.get_node_timer(pos):start(1)
    end,

    on_timer = function(pos, elapsed)
        for _, player in ipairs(minetest.get_objects_inside_radius(pos, 3)) do
            if player:is_player() then
                local player_name = player:get_player_name()
                if not last_heal_time[player_name] or os.time() - last_heal_time[player_name] >= 1 then
                    local hp = player:get_hp()
                    player:set_hp(hp + 1)
                    last_heal_time[player_name] = os.time()
                end
            end
        end
        return true 
    end
})