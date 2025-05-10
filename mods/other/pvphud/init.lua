local hudpos = {x = 0.5, y = 0.5}
local players_data = {}

local huddefs_54 = {
    up    = {hud_elem_type="image", position=hudpos, offset={x=775, y=360}, text="w_key.png", alignment={x=1, y=1}, scale={x=3, y=3}, number=0xFFFFFF},
    left  = {hud_elem_type="image", position=hudpos, offset={x=725, y=410}, text="a_key.png", alignment={x=1, y=1}, scale={x=3, y=3}, number=0xFFFFFF},
    down  = {hud_elem_type="image", position=hudpos, offset={x=775, y=410}, text="s_key.png", alignment={x=1, y=1}, scale={x=3, y=3}, number=0xFFFFFF},
    right = {hud_elem_type="image", position=hudpos, offset={x=825, y=410}, text="d_key.png", alignment={x=1, y=1}, scale={x=3, y=3}, number=0xFFFFFF},
    jump  = {hud_elem_type="image", position=hudpos, offset={x=725, y=460}, text="space_key.png", alignment={x=1, y=1}, scale={x=3, y=3}, number=0xFFFFFF},
    place = {hud_elem_type="image", position=hudpos, offset={x=810, y=250}, text="rmb_key.png", alignment={x=1, y=1}, scale={x=4, y=4}, number=0xFFFFFF},
    dig   = {hud_elem_type="image", position=hudpos, offset={x=730, y=250}, text="lmb_key.png", alignment={x=1, y=1}, scale={x=4, y=4}, number=0xFFFFFF},
    aux1  = {hud_elem_type="image", position=hudpos, offset={x=680, y=460}, text="e_key.png", alignment={x=1, y=1}, scale={x=3, y=3}, number=0xFFFFFF},
    sneak = {hud_elem_type="image", position=hudpos, offset={x=870, y=460}, text="shift_key.png", alignment={x=1, y=1}, scale={x=3, y=3}, number=0xFFFFFF},
}

local huddefs_pre54 = {
    up    = {hud_elem_type="image", position=hudpos, offset={x=775, y=360}, text="w_key.png", alignment={x=1, y=1}, scale={x=3, y=3}, number=0xFFFFFF},
    left  = {hud_elem_type="image", position=hudpos, offset={x=690, y=410}, text="a_key.png", alignment={x=1, y=1}, scale={x=3, y=3}, number=0xFFFFFF},
    down  = {hud_elem_type="image", position=hudpos, offset={x=775, y=410}, text="s_key.png", alignment={x=1, y=1}, scale={x=3, y=3}, number=0xFFFFFF},
    right = {hud_elem_type="image", position=hudpos, offset={x=760, y=410}, text="d_key.png", alignment={x=1, y=1}, scale={x=3, y=3}, number=0xFFFFFF},
    jump  = {hud_elem_type="image", position=hudpos, offset={x=725, y=460}, text="space_key.png", alignment={x=1, y=1}, scale={x=3, y=3}, number=0xFFFFFF},
    place = {hud_elem_type="image", position=hudpos, offset={x=810, y=250}, text="rmb_key.png", alignment={x=1, y=1}, scale={x=4, y=4}, number=0xFFFFFF},
    dig   = {hud_elem_type="image", position=hudpos, offset={x=730, y=250}, text="lmb_key.png", alignment={x=1, y=1}, scale={x=4, y=4}, number=0xFFFFFF},
    aux1  = {hud_elem_type="image", position=hudpos, offset={x=680, y=360}, text="e_key.png", alignment={x=1, y=1}, scale={x=3, y=3}, number=0xFFFFFF},
    sneak = {hud_elem_type="image", position=hudpos, offset={x=870, y=460}, text="shift_key.png", alignment={x=1, y=1}, scale={x=3, y=3}, number=0xFFFFFF},
}

-- Images
local image_press_54 = {
    up="w_key_press.png", left="a_key_press.png", down="s_key_press.png", right="d_key_press.png",
    jump="space_key_press.png", place="rmb_key_press.png", dig="lmb_key_press.png",
    aux1="e_key_press.png", sneak="shift_key_press.png"
}

local image_press_pre54 = {
    up="w_key_press.png", left="a_key_press.png", down="s_key_press.png", right="d_key_press.png",
    jump="space_key_press.png", RMB="rmb_key_press.png", LMB="lmb_key_press.png",
    aux1="e_key_press.png", sneak="shift_key_press.png"
}

local image_normal_54 = {
    up="w_key.png", left="a_key.png", down="s_key.png", right="d_key.png",
    jump="space_key.png", place="rmb_key.png", dig="lmb_key.png",
    aux1="e_key.png", sneak="shift_key.png"
}

local image_normal_pre54 = {
    up="w_key.png", left="a_key.png", down="s_key.png", right="d_key.png",
    jump="space_key.png", RMB="rmb_key.png", LMB="lmb_key.png",
    aux1="e_key.png", sneak="shift_key.png"
}

local function getversion(player)
    local ctl = player:get_player_control()
    if ctl.place == nil then
        return "pre5.4"
    else
        return "5.4"
    end
end

local function get_player_pos(player)
    return player:get_pos()
end

local function get_game_time()
    local time = minetest.get_timeofday() * 24000
    local hours = math.floor(time / 1000)
    local minutes = math.floor((time % 1000) / 1000 * 60)
    return string.format("%02d:%02d", hours, minutes)
end

local function setup_hud(player)
    local name = player:get_player_name()
    if players_data[name] and players_data[name].hud_ids then
        return
    end

    local version = getversion(player)
    local keys = {"up", "left", "down", "right", "jump", "aux1", "sneak"}
    local huddefs
    local image_press
    local image_normal

    if version == "pre5.4" then
        table.insert(keys, "RMB")
        table.insert(keys, "LMB")
        huddefs = huddefs_pre54
        image_press = image_press_pre54
        image_normal = image_normal_pre54
    else
        table.insert(keys, "place")
        table.insert(keys, "dig")
        huddefs = huddefs_54
        image_press = image_press_54
        image_normal = image_normal_54
    end

    local hud_ids = {}
    for _, key in ipairs(keys) do
        hud_ids[key] = player:hud_add(huddefs[key])
    end

    local fps_hud = player:hud_add({hud_elem_type="text", position=hudpos, offset={x=-950, y=400}, text="FPS: 0", alignment={x=1, y=1}, scale={x=2, y=2}, number=0xFFFFFF})
    local pos_hud = player:hud_add({hud_elem_type="text", position=hudpos, offset={x=-950, y=420}, text="pos: 0, 0, 0", alignment={x=1, y=1}, scale={x=2, y=2}, number=0xFFFFFF})
    local time_hud = player:hud_add({hud_elem_type="text", position=hudpos, offset={x=-950, y=340}, text="Time: 00:00", alignment={x=1, y=1}, scale={x=2, y=2}, number=0xFFFFFF})
    local rmb_hud = player:hud_add({hud_elem_type="text", position=hudpos, offset={x=-950, y=360}, text="RMB CPS: 0", alignment={x=1, y=1}, scale={x=2, y=2}, number=0xFFFFFF})
    local lmb_hud = player:hud_add({hud_elem_type="text", position=hudpos, offset={x=-950, y=380}, text="LMB CPS: 0", alignment={x=1, y=1}, scale={x=2, y=2}, number=0xFFFFFF})

    players_data[name] = {
        active = true,
        version = version,
        keys = keys,
        huddefs = huddefs,
        image_press = image_press,
        image_normal = image_normal,
        before = {},
        hud_ids = hud_ids,
        fps_hud = fps_hud,
        pos_hud = pos_hud,
        time_hud = time_hud,
        rmb_hud = rmb_hud,
        lmb_hud = lmb_hud,
        rmb_clicks = 0,
        lmb_clicks = 0,
        rmb_pressed = false,
        lmb_pressed = false,
        rmb_timer = 0,
        lmb_timer = 0,
        timer = 0,
    }
end

local function remove_hud(player)
    local name = player:get_player_name()
    if not players_data[name] then return end
    for _, id in pairs(players_data[name].hud_ids) do
        player:hud_remove(id)
    end
    player:hud_remove(players_data[name].fps_hud)
    player:hud_remove(players_data[name].pos_hud)
    player:hud_remove(players_data[name].time_hud)
    player:hud_remove(players_data[name].rmb_hud)
    player:hud_remove(players_data[name].lmb_hud)
    players_data[name] = nil
end

minetest.register_chatcommand("pvphud", {
    description = "Toggle PvP HUD display",
    func = function(name)
        local player = minetest.get_player_by_name(name)
        if not player then return end

        local meta = player:get_meta()

		if players_data[name] then
			remove_hud(player)
			meta:set_string("pvphud_active", "false")
			minetest.chat_send_player(name, minetest.colorize("#FF0000", "PvP HUD disabled."))
		else
			setup_hud(player)
			meta:set_string("pvphud_active", "true")
			minetest.chat_send_player(name, minetest.colorize("#00FF00", "PvP HUD activated."))
		end

    end
})


minetest.register_globalstep(function(dtime)
    for name, data in pairs(players_data) do
        local player = minetest.get_player_by_name(name)
        if not player then
            players_data[name] = nil
            return
        end

        local ctl = player:get_player_control()

        if (data.version == "pre5.4" and ctl.RMB and not data.rmb_pressed) or (data.version == "5.4" and ctl.place and not data.rmb_pressed) then
            data.rmb_clicks = data.rmb_clicks + 1
        end
        data.rmb_pressed = (data.version == "pre5.4") and ctl.RMB or ctl.place

        if (data.version == "pre5.4" and ctl.LMB and not data.lmb_pressed) or (data.version == "5.4" and ctl.dig and not data.lmb_pressed) then
            data.lmb_clicks = data.lmb_clicks + 1
        end
        data.lmb_pressed = (data.version == "pre5.4") and ctl.LMB or ctl.dig

        data.rmb_timer = data.rmb_timer + dtime
        data.lmb_timer = data.lmb_timer + dtime

        if data.rmb_timer >= 1 then
            player:hud_change(data.rmb_hud, "text", "RMB CPS: " .. data.rmb_clicks)
            data.rmb_clicks = 0
            data.rmb_timer = 0
        end
        if data.lmb_timer >= 1 then
            player:hud_change(data.lmb_hud, "text", "LMB CPS: " .. data.lmb_clicks)
            data.lmb_clicks = 0
            data.lmb_timer = 0
        end

        data.timer = data.timer + dtime
        if data.timer >= 0.1 then
            local fps = math.floor(1/dtime)
            player:hud_change(data.fps_hud, "text", "FPS: " .. fps)

            local pos = get_player_pos(player)
            player:hud_change(data.pos_hud, "text", string.format("Pos: %.1f, %.1f, %.1f", pos.x, pos.y, pos.z))

            player:hud_change(data.time_hud, "text", "Time: " .. get_game_time())

            data.timer = 0
        end

        for _, key in ipairs(data.keys) do
            if ctl[key] and not data.before[key] then
                player:hud_change(data.hud_ids[key], "text", data.image_press[key])
                data.before[key] = true
            elseif not ctl[key] and data.before[key] then
                player:hud_change(data.hud_ids[key], "text", data.image_normal[key])
                data.before[key] = false
            end
        end
    end
end)

minetest.register_on_joinplayer(function(player)
    local name = player:get_player_name()
    local meta = player:get_meta()
    local hud_status = meta:get_string("pvphud_active")

    if hud_status == "true" then
        setup_hud(player)
    end
end)
