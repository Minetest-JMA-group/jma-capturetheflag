local timer
local spawn_interval = 60

local function spawn_giftbox()
    local spawn_amount = math.max(1, math.min(#minetest.get_connected_players(), 20))

    local vm = VoxelManip()
    local pos1, pos2 = vm:read_from_map(ctf_map.current_map.pos1, ctf_map.current_map.pos2)

    local Nx = pos2.x - pos1.x + 1
    -- local Ny = pos2.y - pos1.y + 1
    local Nz = pos2.z - pos1.z + 1

    local Sx = pos1.x
    -- local Sy = pos1.y
    local Sz = pos1.z

    for _ = 1, spawn_amount do
        local x = math.random(Sx + 10, Sx + Nx - 10)  -- X offset
        local z = math.random(Sz + 10, Sz + Nz - 10)  -- Z offset

        local y = pos2.y - math.random(10, 30)  -- Ceiling height with indentation -10

        local valid_spawn = true

        -- Checking for air from spawn position in Y to the surface with a limit
        for i = 1, 30 do
            local node_at = minetest.get_node_or_nil({x = x, y = y - i, z = z})

            if not node_at or node_at.name ~= "air" then
                valid_spawn = false
                break
            end
        end

        if valid_spawn then
            local spawn_pos = {x = x, y = y, z = z}
            minetest.add_entity(spawn_pos, "random_gifts:gift")
        end
    end
    timer = minetest.after(spawn_interval, spawn_giftbox)
end

ctf_api.register_on_new_match(function()
    timer = minetest.after(5, spawn_giftbox)
end)

ctf_api.register_on_match_end(function()
    if timer then
    	timer:cancel()
    end
end)
