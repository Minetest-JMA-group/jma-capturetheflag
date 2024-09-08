-- SPDX-License-Identifier: GPL-3.0-or-later
-- Copyright (c) 2024 Ivan Shkatov (Maintainer_) ivanskatov672@gmail.com
spectator = {}
spectator.spectators = {}
spectator.texture = "question.png"

-- Enabled spectator mode
function spectator.on(player)
    if player then 
        local name = player:get_player_name()
        local meta = player:get_meta()
    
        meta:set_string(name, minetest.privs_to_string(minetest.get_player_privs(name), ","))
        meta:set_int("spectator", 1)
    
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
    
        spectator.spectators[name] = true
    end
end

-- Disabled spectator mode
function spectator.off(player)
    if player then
        local name = player:get_player_name()
        local meta = player:get_meta()
    
        minetest.set_player_privs(name, minetest.string_to_privs(meta:get_string(name), ","))
        meta:set_string(name, "")
        meta:set_int("spectator", 0)
    
        player:set_properties({
            visual = "mesh",
            show_on_minimap = true,
            pointable = true,
        })
        player:set_nametag_attributes {text = name}
        player:set_armor_groups({immortal = 0})
    
        spectator.spectators[name] = nil
    end
end

ctf_api.register_on_match_end(function()
    for player_name,_ in pairs(spectator.spectators) do
        spectator.off(minetest.get_player_by_name(player_name))
    end
end)

ctf_api.register_on_match_start(function()
    for _, player in pairs(minetest.get_connected_players()) do
        spectator.formspec(player:get_player_name())
    end
end)

spectator.formspec = function (playername)
    local formspec = "size[8,3]bgcolor[#080808BB;true]" .. default.gui_bg .. default.gui_bg_img .. [[
    hypertext[2.3,0.1;5,1;title;<b>Spectator mode<\b>]
    image[0,0;2,2;spectator_question.png]
    button_exit[1.5,2.3;2,0.8;yes;Yes]
    button_exit[3.5,2.3;2,0.8;no;No]
    button_exit[5.5,2.3;2,0.8;cancel;Cancel]
    ]]
    formspec = formspec .. "label[2.3,0.7;" .. "Watch the game?" .. "]"

    minetest.show_formspec(playername, "spectator_mode", formspec)
end

minetest.register_on_player_receive_fields(function(player, formname, fields)
    if formname ~= "spectator_mode" then
		return 
    end
    if fields["yes"] then
        spectator.on(player)
    end

	return true
end)

minetest.register_chatcommand("spectator", {
    description = "Shows players in spectator mode",
    params = "",
    func = function (name)
        local output = {}
        for i,_ in pairs(spectator.spectators) do
            table.insert(output, i)
        end
        table.sort(output)
        minetest.chat_send_player(name, "In spectator mode now: " .. table.concat(output, ", "))
    end
})

minetest.register_on_joinplayer(function(player)
    local name = player:get_player_name()
    local meta = player:get_meta()
    if meta:get_int("spectator") == 1 then
        minetest.set_player_privs(name, minetest.string_to_privs(meta:get_string(name), ","))
        meta:set_int("spectator", 0)
    end 
end)
