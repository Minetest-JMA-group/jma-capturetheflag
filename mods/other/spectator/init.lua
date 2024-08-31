-- SPDX-License-Identifier: GPL-3.0-or-later
-- Copyright (c) 2024 Ivan Shkatov (Maintainer_) ivanskatov672@gmail.com
spectator = {}
spectator.in_ = {}

-- Override interact privilege
minetest.register_privilege("interact", {
    description = "Can interact with things and modify the world",
    give_to_admin = false,
    give_to_singleplayer = false
})

-- Override shout privilege
minetest.register_privilege("shout", {
    description = "Can speak in chat",
    give_to_admin = false,
    give_to_singleplayer = false
})

-- Enabled spectator mode
spectator.on = function (player)
    local name = player:get_player_name()
    local meta = player:get_meta()

    meta:set_string(name, minetest.privs_to_string(minetest.get_player_privs(name), ","))
    meta:set_bool("spectator", true)

    minetest.set_player_privs(name, {
        noclip = true,
        fly = true,
        fast = true
    })

    player:set_properties({
        visual = "",
        show_on_minimap = false,
        pointable = false,
    })
    player:set_nametag_attributes({color={a=0},text = " "})
    player:set_nametag_attributes{text = "\0"}
    player:set_armor_groups({immortal = 1})
    player:get_inventory():set_list("main", {})
    player:get_inventory():set_list("craft", {})
    player:get_inventory():set_list("craftpreview", {})

    spectator.in_[name] = true
end

-- Disabled spectator mode
spectator.off = function (player)
    local name = player:get_player_name()
    local meta = player:get_meta()

    minetest.set_player_privs(name, minetest.string_to_privs(meta:get_string(name), ","))
    meta:set_string(name, "")
    meta:set_bool("spectator", false)

    player:set_properties({
        visual = "mesh",
        show_on_minimap = true,
        pointable = true,
    })

    player:set_nametag_attributes {text = name}
    player:set_armor_groups({immortal = 0})

    spectator.in_[name] = nil
end

ctf_api.register_on_match_end(function()
    for i,_ in pairs(spectator.in_) do
        spectator.off(minetest.get_player_by_name(i))
    end
end)

ctf_api.register_on_match_start(function()
    for _, v in pairs(minetest.get_connected_players()) do
        spectator.formspec(v:get_player_name())
    end
end)

spectator.formspec = function (playername)
    local formspec = "size[8,3]bgcolor[#080808BB;true]" .. default.gui_bg .. default.gui_bg_img .. [[
        hypertext[2.3,0.1;5,1;title;<b>Spectator mode<\b>]
        image[0,0;2,2;question.png]
        button_exit[1.5,2.3;2,0.8;yes;Yes]
        button_exit[3.5,2.3;2,0.8;no;No]
        button_exit[5.5,2.3;2,0.8;cancel;Cancel]
        ]]
    formspec = formspec .. "label[2.3,0.7;" .. "Watch the game?" .. "]"

    minetest.after(0.2, minetest.show_formspec, playername, "Watch the game?", formspec)
    
end

minetest.register_on_player_receive_fields(function(player, formname, fields)
    if fields["yes"] then
        spectator.on(player)
    end
end)

minetest.register_chatcommand("spectator", {
    description = "",
    params = "",
    func = function (name)
        for i,_ in pairs(spectator.in_) do
            minetest.chat_send_player(name, i)
        end
    end
})

minetest.register_on_joinplayer(function(player)
    local name = player:get_player_name()
    local meta = player:get_meta()
    if meta:get_bool("spectator") then
        minetest.set_player_privs(name, minetest.string_to_privs(meta:get_string(name), ","))
    end 
    spectator.formspec(name)
end)

