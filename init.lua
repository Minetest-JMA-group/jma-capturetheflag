local INVIS_DURATION = 10
local BUBBLE_INTERVAL = 0.2
local POTION_COOLDOWN = 30 
local invisible_players = {}
local last_drink_time = {}

minetest.register_craftitem("invis_potion:potion", {
    description = "Invisible Potion",
    inventory_image = "invis_potion.png",
    on_use = function(itemstack, user, pointed_thing)
        if not user or not user:is_player() then return end
        local name = user:get_player_name()

        local now = os.time()
        if last_drink_time[name] and now - last_drink_time[name] < POTION_COOLDOWN then
            local remaining = POTION_COOLDOWN - (now - last_drink_time[name])
            minetest.chat_send_player(name, "Potion is on cooldown! Wait " .. remaining .. " seconds.")
            return itemstack
        end

        user:set_properties({
            visual_size = {x = 0, y = 0},
            makes_footstep_sound = false
        })
        user:set_observers({})
        invisible_players[name] = {
            time_left = INVIS_DURATION,
            bubble_timer = 0
        }

        last_drink_time[name] = now
        itemstack:take_item()

        minetest.chat_send_player(name, "You are invisible now!")

        return itemstack
    end,
})

minetest.register_globalstep(function(dtime)
    for name, data in pairs(invisible_players) do
        local player = minetest.get_player_by_name(name)
        if not player then
            invisible_players[name] = nil
        else
            data.time_left = data.time_left - dtime
            data.bubble_timer = data.bubble_timer + dtime

            if data.bubble_timer >= BUBBLE_INTERVAL then
                data.bubble_timer = 0
                local pos = player:get_pos()
                local offset = {
                    x = math.random(-5, 5) * 0.1,
                    y = math.random(0, 15) * 0.1,
                    z = math.random(-5, 5) * 0.1
                }
                minetest.add_particle({
                    pos = {x=pos.x+offset.x, y=pos.y+1+offset.y, z=pos.z+offset.z},
                    velocity = {x=0, y=0.5, z=0},
                    expirationtime = 1,
                    size = 2,
                    texture = "bubble.png",
                    glow = 5
                })
            end

            if data.time_left <= 0 then
                player:set_properties({
                    visual_size = {x = 1, y = 1},
                    makes_footstep_sound = true
                })
                player:set_observers(nil)
                invisible_players[name] = nil
                minetest.chat_send_player(name, "You are now visible again!")
            end
        end
    end
end)

minetest.register_on_punchplayer(function(player, hitter)
    if hitter and hitter:is_player() then
        local name = hitter:get_player_name()
        if invisible_players[name] then
            return true
        end
    end
end)

minetest.register_on_player_hpchange(function(player, hp_change, reason)
    if hp_change < 0 and reason.type == "punch" then
        local name = player:get_player_name()
        if invisible_players[name] then
            return 0
        end
    end
    return hp_change
end, true)

if minetest.get_modpath("ctf") then
    ctf.register_on_capture(function(flag, player)
        if not player or not player:is_player() then return end
        local name = player:get_player_name()
        if invisible_players[name] then
            player:set_properties({
                visual_size = {x = 1, y = 1},
                makes_footstep_sound = true
            })
            player:set_observers(nil)
            invisible_players[name] = nil
            minetest.chat_send_player(name, "You became visible after capturing the flag!")
        end
    end)
end
