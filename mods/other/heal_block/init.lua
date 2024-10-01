-- SPDX-License-Identifier: GPL-3.0-or-later
-- Copyright (c) 2024 Ivan Shkatov (Maintainer_) ivanskatov672@gmail.com

minetest.register_node("heal_block:heal", {
    description = "Healing Block\n"
        .. "A block that heals players within a 3-block radius.\n"
        .. "Place it on your team's territory to keep your allies healthy nearby.\n"
        .. minetest.colorize("yellow", "Warning: breaking this block will result in its loss, so defend it wisely!"),
    drawtype = "nodebox",
    node_box = {
        type = "fixed",
        fixed = {-0.5, -0.5, -0.5, 0.5, 0, 0.5}
    },
    walkable = true,
    tiles = {
        {name = "heal_block_top.png", align_style = "repeat", scale = 1, position = {x = 0, y = 0, z = 0.5}}, -- top
        {name = "default_snow.png"}
    },
    groups = {snappy=2,cracky=3,oddly_breakable_by_hand=3},
    drop = "",

    on_place = function(itemstack, placer, pointed_thing)
        local pteam = ctf_teams.get(placer)
        if pteam then
            if not ctf_core.pos_inside(pointed_thing.under, ctf_teams.get_team_territory(pteam)) then
                hud_events.new(placer, {
                    quick = true,
                    text =  "Healing block can only be placed on your team's area.",
                    color = "warning",
                })
                return
            end
        end
        minetest.item_place(itemstack, placer, pointed_thing)
        return itemstack
    end,

    on_construct = function(pos)
        minetest.get_node_timer(pos):start(1)
    end,

    on_timer = function(pos)
        for _, player in ipairs(minetest.get_objects_inside_radius(pos, 3)) do
            if player:is_player() then
                local hp = player:get_hp()
                if hp < player:get_properties().hp_max then
                    player:set_hp(hp + 1)
                end
            end
        end
        return true
    end
})