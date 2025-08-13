local cooldowns = {}

local MAX_RANDOM_ATTEMPTS = 16
local SEARCH_RADIUS = 8
local TELEPORT_COOLDOWN = 1
local PADDING = 5 -- some maps have ground out of barrier

local play_sound = false
local allow_teleport = true
if minetest.get_modpath("default") then
    play_sound = true
end

local function get_world_bounds()
    return {x = -31000, y = -31000, z = -31000}, {x = 31000, y = 31000, z = 31000}
end

local world_bound_pos1, world_bound_pos2 = get_world_bounds()

local function clamp(value, min, max)
    return math.max(min, math.min(max, value))
end

minetest.register_on_leaveplayer(function(player)
    cooldowns[player:get_player_name()] = nil
end)


local function set_cd(pname)
    cooldowns[pname] = minetest.get_gametime() + TELEPORT_COOLDOWN
end

local function get_cd(pname)
    return cooldowns[pname] or 0
end

local function is_on_cd(pname)
    return minetest.get_gametime() < get_cd(pname)
end


local function is_water(node_def)
    if node_def.name == "default:water_source" or node_def.name == "default:river_water_source" then
        return true
    end
    return false
end


local function is_node_safe_for_player(node_name)
    local node_def = minetest.registered_nodes[node_name]
    if not node_def then
        return false
    end

    if is_water(node_def) then
        return true
    end

    if node_def.walkable or (node_def.damage_per_second and node_def.damage_per_second > 0) then
        return false
    end
    return true
end

local function find_ground_in_column(column_pos, search_up, search_down)
    local consecutive_safe_blocks = 0
    local start_y = column_pos.y + search_up
    local end_y = column_pos.y - search_down
    for y = start_y, end_y, -1 do
        local test_pos = {x = column_pos.x, y = y, z = column_pos.z}
        local node = minetest.get_node(test_pos)
        local node_def = minetest.registered_nodes[node.name]
        if is_node_safe_for_player(node.name) then
            consecutive_safe_blocks = consecutive_safe_blocks + 1
        elseif node_def and (node_def.walkable or is_water(node_def)) and consecutive_safe_blocks > 1 then
            return {x = test_pos.x, y = test_pos.y + 1, z = test_pos.z}
        else
            consecutive_safe_blocks = 0
        end
    end

    return nil
end


local function clamp_x(pos_x)
    return clamp(pos_x, world_bound_pos1.x + PADDING, world_bound_pos2.x - PADDING)
end

local function clamp_y(pos_y)
    return clamp(pos_y, world_bound_pos1.y, world_bound_pos2.y)
end

local function clamp_z(pos_z)
    return clamp(pos_z, world_bound_pos1.z + PADDING, world_bound_pos2.z - PADDING)
end

local function find_teleport_position(pos)
    -- random search
    for attempt = 1, MAX_RANDOM_ATTEMPTS do
        local random_pos = {
            x = clamp_x(pos.x + math.random(-SEARCH_RADIUS, SEARCH_RADIUS)),
            y = clamp_y(pos.y + math.random(-SEARCH_RADIUS, SEARCH_RADIUS)),
            z = clamp_z(pos.z + math.random(-SEARCH_RADIUS, SEARCH_RADIUS))
        }

        local teleport_spot = find_ground_in_column(random_pos, 1, 8)
        if teleport_spot then
            return teleport_spot
        end
    end

    -- bruteforce

    local valid_teleport_spots = {}

    for offset = -SEARCH_RADIUS, SEARCH_RADIUS do
        for perp_offset = -1, 1 do
            if not (offset == 0 and perp_offset == 0) then
                -- varying x, fixed z
                local new_pos = {x = clamp_x(pos.x + offset),
                        y = clamp_y(pos.y),
                        z = clamp_z(pos.z + perp_offset)}
                local spot = find_ground_in_column(new_pos, 2, 2)
                if spot then
                    table.insert(valid_teleport_spots, spot)
                end
                -- varying z, fixed x
                new_pos = {x = clamp_x(pos.x + perp_offset),
                        y = clamp_y(pos.y),
                        z = clamp_z(pos.z + offset)}
                spot = find_ground_in_column(new_pos, 2, 2)
                if spot then
                    table.insert(valid_teleport_spots, spot)
                end
            end
        end
    end
    if #valid_teleport_spots > 0 then
        return valid_teleport_spots[math.random(#valid_teleport_spots)]
    end

    return nil
end



local function teleport_player(player)
    local pname = player:get_player_name()
    local new_pos = find_teleport_position(player:get_pos())
    if new_pos then
        if play_sound then
            minetest.sound_play("fire_extinguish_flame", {
                pos = player:get_pos(),
                gain = 0.4,
                pitch = 0.8
            })
        end

        player:set_pos(new_pos)

        if play_sound then
            minetest.after(0.1, function()
                minetest.sound_play("fire_extinguish_flame", {
                    pos = new_pos,
                    gain = 0.6,
                    pitch = 1.4
                })
            end)
        end

        minetest.add_particlespawner({
            amount = 100,
            time = 1,
            minpos = vector.subtract(new_pos, 1),
            maxpos = vector.add(new_pos, 2),
            texture = "enderium.png"
        })
    end
    set_cd(pname)
end


if minetest.get_modpath("ctf_api") and minetest.get_modpath("ctf_map") then
    ctf_api.register_on_match_start(function ()
        minetest.after(0, function ()
            world_bound_pos1 = ctf_map.current_map.pos1
            world_bound_pos2 = ctf_map.current_map.pos2
            allow_teleport = true
        end)
    end)

    ctf_api.register_on_match_end(function ()
        world_bound_pos1, world_bound_pos2 = get_world_bounds()
        allow_teleport = false
    end)
else
    allow_teleport = true
end

minetest.register_node("more_liquids:enderium_source", {
    description = "Enderium source",
    drawtype = "liquid",
    waving = 3,
    tiles = {
        {
            name = "enderium_source_animated.png",
            backface_culling = false,
            animation = {
                type = "vertical_frames",
                aspect_w = 16,
                aspect_h = 16,
                length = 4.0,
            },
        },
        {
            name = "enderium_source_animated.png",
            backface_culling = true,
            animation = {
                type = "vertical_frames",
                aspect_w = 16,
                aspect_h = 16,
                length = 4.0,
            },
        }
    },
    use_texture_alpha = "blend",
    paramtype = "light",
    light_source = 8,
    walkable = false,
    pointable = false,
    diggable = false,
    buildable_to = true,
    is_ground_content = false,
    drop = "",
    damage_per_second = 1,
	drowning = 1,
	liquidtype = "source",
    liquid_alternative_flowing = "more_liquids:enderium_flowing",
	liquid_alternative_source = "more_liquids:enderium_source",
	liquid_viscosity = 1,
    liquid_range = 4,
    liquid_renewable = false,
    groups = {liquid = 2},
    post_effect_color = {a = 180, r = 11, g = 77, b = 66},
})

minetest.register_node("more_liquids:enderium_flowing", {
    description = "Flowing enderium",
    drawtype = "flowingliquid",
    waving = 3,
    tiles = {"enderium.png"},
    special_tiles = {
        {
            name = "enderium_flowing_animated.png",
            backface_culling = false,
            animation = {
                type = "vertical_frames",
                aspect_w = 16,
                aspect_h = 16,
                length = 4.0,
            },
        },
        {
            name = "enderium_flowing_animated.png",
            backface_culling = true,
            animation = {
                type = "vertical_frames",
                aspect_w = 16,
                aspect_h = 16,
                length = 4.0,
            },
        }
    },
    use_texture_alpha = "blend",
    paramtype = "light",
    paramtype2 = "flowingliquid",
    light_source = 8,
    walkable = false,
	pointable = false,
	diggable = false,
	buildable_to = true,
	is_ground_content = false,
	drop = "",
    damage_per_second = 1,
	drowning = 1,
	liquidtype = "flowing",
    liquid_alternative_flowing = "more_liquids:enderium_flowing",
	liquid_alternative_source = "more_liquids:enderium_source",
	liquid_viscosity = 1,
    liquid_range = 4,
    liquid_renewable = false,

    groups = {liquid = 2},
    post_effect_color = {a = 180, r = 11, g = 77, b = 66},
})


minetest.register_globalstep(function(dtime)
    if not allow_teleport then return end

    for _, player in ipairs(minetest.get_connected_players()) do
        local pname = player:get_player_name()
        if not is_on_cd(pname) then
            local pos = player:get_pos()
            local waist_pos = {x = pos.x, y = pos.y + 0.5, z = pos.z}
            local head_pos = {x = pos.x, y = pos.y + 1.5, z = pos.z}
            local node = minetest.get_node(waist_pos)
            local node_at_head = minetest.get_node(head_pos)

            if node.name == "more_liquids:enderium_source" or
               node.name == "more_liquids:enderium_flowing" or 
               node_at_head.name == "more_liquids:enderium_source" or
               node_at_head.name == "more_liquids:enderium_flowing" then
                teleport_player(player)
            end
        end
    end
end)

minetest.register_chatcommand("enderium_rtp", {
    description = "Tests enderium teleportation",
    privs = {server = true},
    func = function (name, param)
        local player = minetest.get_player_by_name(name)

        if not player then
            return false, "Player not found"
        end

        local new_pos = find_teleport_position(player:get_pos())
        if new_pos then
            player:set_pos(new_pos)
            return true, "Teleported to " .. minetest.pos_to_string(new_pos)
        else
            return false, "No safe teleport location found"
        end
    end
})