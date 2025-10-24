
minetest.register_node("nightvision:glow_effect", {
    description = "Night Vision Glow",
    drawtype = "airlike",
    light_source = 14,
    walkable = false,
    pointable = false,
    diggable = false,
    buildable_to = true,
    groups = {not_in_creative_inventory = 1},
})


local cooldown_time = 300


nightvision_last_use = nightvision_last_use or {}
nightvision_active = nightvision_active or {}


local warning_times = {30, 20, 10, 5, 4, 3, 2, 1}

minetest.register_craftitem("nightvision:night_vision_potion", {
    description = "Night Vision Potion",
    inventory_image = "nightvision_potion.png",
    groups = {food = 1},  -- shows in creative inventory
    on_use = function(itemstack, user, pointed_thing)
        local player_name = user:get_player_name()


        local last_use = nightvision_last_use[player_name] or 0
        local now = os.time()
        if now - last_use < cooldown_time then
            local remain = cooldown_time - (now - last_use)
            minetest.chat_send_player(player_name, math.ceil(remain) .. " seconds cooldown left")
            return itemstack
        end

        nightvision_last_use[player_name] = now


        local radius = 20
        local duration = 60
        local glow_nodes = {}

        nightvision_active[player_name] = {
            player = user,
            glow_nodes = glow_nodes,
            timer = 0,
            duration = duration,
            radius = radius,
            warned_times = {}
        }


        itemstack:take_item()
        minetest.chat_send_player(player_name, "Night Vision activated!")
        return itemstack
    end,
})

minetest.register_globalstep(function(dtime)
    for player_name, data in pairs(nightvision_active) do
        data.timer = data.timer + dtime
        data.duration = data.duration - dtime

        local pos = data.player:get_pos()


        if data.duration <= 0 then
            for _, p in ipairs(data.glow_nodes) do
                if minetest.get_node(p).name == "nightvision:glow_effect" then
                    minetest.set_node(p, {name="air"})
                end
            end

            minetest.chat_send_player(player_name, "Night Vision potion is expired!")

            nightvision_active[player_name] = nil
        else

            if data.timer >= 0.5 then
                data.timer = 0

                for _, p in ipairs(data.glow_nodes) do
                    if minetest.get_node(p).name == "nightvision:glow_effect" then
                        minetest.set_node(p, {name="air"})
                    end
                end
                data.glow_nodes = {}

                local radius = data.radius
                for x = -radius, radius, 4 do
                    for y = -radius, radius, 4 do
                        for z = -radius, radius, 4 do
                            if x*x + y*y + z*z <= radius*radius then
                                local p = {x=pos.x+x, y=pos.y+y, z=pos.z+z}
                                if minetest.get_node(p).name == "air" then
                                    minetest.set_node(p, {name="nightvision:glow_effect"})
                                    table.insert(data.glow_nodes, p)
                                end
                            end
                        end
                    end
                end
            end

            for _, t in ipairs(warning_times) do
                if data.duration <= t and not data.warned_times[t] then
                    minetest.chat_send_player(player_name, t .. " seconds left")
                    data.warned_times[t] = true
                end
            end
        end
    end
end)
