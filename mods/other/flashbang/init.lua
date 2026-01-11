local modname = minetest.get_current_modname() or "flashbang"

local BLIND_RADIUS = 5
local BLIND_DURATION = 10
local EXPLOSION_PARTICLES = 70
local EXPLOSION_SOUND = "ctf_ranged_explode"

local blind_hud_by_player = {}

local function apply_blind(player, duration)
    if not player or not player:is_player() then return end
    local name = player:get_player_name()

    if blind_hud_by_player[name] then
        pcall(function() player:hud_remove(blind_hud_by_player[name].id) end)
        blind_hud_by_player[name] = nil
    end

    local hud_id = player:hud_add({
        hud_elem_type = "image",
        position = { x = 0.5, y = 0.5 },
        offset = { x = 0, y = 0 },
        scale = { x = 1024, y = 1024 },
        text = modname .. "_overlay.png",
        alignment = { x = 0, y = 0 },
        z_index = 1000,
    })

    blind_hud_by_player[name] = { id = hud_id, alpha = 255 }

    local step = 0.1
    local function fade()
        if not player or not player:is_player() then return end
        if not blind_hud_by_player[name] then return end

        local data = blind_hud_by_player[name]
        data.alpha = data.alpha - math.floor(255 * (step / duration))

        if data.alpha <= 0 then
            pcall(function() player:hud_remove(data.id) end)
            blind_hud_by_player[name] = nil
            return
        end

        player:hud_change(data.id, "text", modname .. "_overlay.png^[opacity:" .. data.alpha)
        minetest.after(step, fade)
    end

    minetest.after(step, fade)
end

local function explosion_effect(pos)
    minetest.sound_play(EXPLOSION_SOUND, { pos = pos, gain = 1.2, max_hear_distance = 24 })

    for i = 1, EXPLOSION_PARTICLES do
        local dir = { x = (math.random() - 0.5) * 2, y = (math.random() - 0.2) * 2, z = (math.random() - 0.5) * 2 }
        local vel = vector.multiply(dir, math.random() * 7)
        minetest.add_particle({
            pos = pos,
            velocity = vel,
            acceleration = { x = vel.x * -0.5, y = -3, z = vel.z * -0.5 },
            expirationtime = 0.8 + math.random() * 1.4,
            size = 4 + math.random() * 8,
            collisiondetection = false,
            vertical = false,
            texture = "tnt_smoke.png",
        })
    end
end

local function duration_by_distance(dist)
    if dist <= 0 then return BLIND_DURATION end
    if dist >= BLIND_RADIUS then return 0 end
    local t = 1 - (dist / BLIND_RADIUS)
    return math.max(1, math.floor(BLIND_DURATION * t + 0.5))
end

minetest.register_entity(modname .. ":grenade_entity", {
    initial_properties = {
        physical = true,
        collide_with_objects = false,
        pointable = false,
        collisionbox = { -0.1, -0.1, -0.1, 0.1, 0.1, 0.1 },
        visual = "sprite",
        textures = { "flashbang_grenade.png" },
        visual_size = { x = 0.7, y = 0.7 },
    },

    timer = 0,
    gravity = 9.8,

    on_step = function(self, dtime)
        self.timer = (self.timer or 0) + dtime
        local pos = self.object:get_pos()
        if not pos then return end

        local below = { x = pos.x, y = pos.y - 0.2, z = pos.z }
        local node = minetest.get_node_or_nil(below)

        if node and node.name and node.name ~= "air" then
            local expl_pos = vector.round(pos)
            explosion_effect(expl_pos)

            for _, player in pairs(minetest.get_connected_players()) do
                local ppos = player:get_pos()
                local dist = vector.distance(ppos, expl_pos)
                if dist <= BLIND_RADIUS then
                    local dur = duration_by_distance(dist)
                    if dur > 0 then
                        apply_blind(player, dur)
                    end
                end
            end

            self.object:remove()
            return
        end

        if self.timer > 10 then
            self.object:remove()
        end
    end,
})

minetest.register_craftitem(modname .. ":grenade", {
    description = "Flashbang Grenade",
    inventory_image = "flashbang_grenade.png",
    stack_max = 1,

    on_use = function(itemstack, user, pointed_thing)
        if not user or not user:is_player() then return itemstack end

        local pos = user:get_pos()
        local dir = user:get_look_dir()
        local spawn_pos = vector.add(pos, { x = dir.x * 1.5, y = 1.4, z = dir.z * 1.5 })

        local obj = minetest.add_entity(spawn_pos, modname .. ":grenade_entity")
        if obj then
            local vel = vector.multiply(dir, 18)
            vel.y = vel.y + 4
            obj:set_velocity(vel)
            obj:set_acceleration({ x = 0, y = -9.8, z = 0 })
            obj:set_attach(user, "", { x = 0, y = 0, z = 0 }, { x = 0, y = 0, z = 0 })
            obj:set_detach()
        end

        itemstack:take_item()
        return itemstack
    end,
})
