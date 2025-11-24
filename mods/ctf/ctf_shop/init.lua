if type(ctf_api) ~= "table" or type(ctf_teams) ~= "table" or type(ctf_modebase) ~= "table" or type(ctf_settings) ~= "table" then
    return
end

local function contains(tbl, val)
    if type(tbl) ~= "table" then
        return false
    end
    for _, v in ipairs(tbl) do
        if v == val then
            return true
        end
    end
    return false
end

ctf_shop = {}

ctf_settings.register("ctf_shop:automatic_shop_display", {
    type = "bool",
    label = "Automatic Shop Display",
    description = "Enables the automatic display of the shop as soon as a new match begins.",
    default = "true",
})

local max_coins = 120
local start_coin_amount = 40
local coins_per_minute = 3

local players_coins = {}

local all_modes = ctf_modebase.modelist

local give_timer = 0
minetest.register_globalstep(function(dtime)
    give_timer = give_timer + dtime
    if give_timer >= 60 then
        give_timer = 0
        for player_name, coin_amount in pairs(players_coins) do
            players_coins[player_name] = math.min(coin_amount + coins_per_minute, max_coins)
        end
    end
end)

local shop_items = {
    --nodes
    {item_string = "default:steelblock 32", price = 40, modes = all_modes},
    --{item_string = "default:mese 64", price = 40, modes = all_modes},
    {item_string = "default:obsidian 32", price = 20, modes = all_modes},
    {item_string = "ctf_map:reinforced_cobble 40", price = 20, modes = all_modes},
    {item_string = "ctf_map:damage_cobble 20", price = 15, modes = all_modes},
    {item_string = "default:stonebrick 64", price = 10, modes = all_modes},
    {item_string = "default:obsidian_glass 32", price = 5, modes = all_modes},
    {item_string = "xpanes:obsidian_pane_flat 32", price = 5, modes = all_modes},

    {item_string = "default:acacia_tree 32", price = 5, modes = all_modes},
    {item_string = "default:acacia_wood 32", price = 5, modes = all_modes},
    {item_string = "default:aspen_tree 32", price = 5, modes = all_modes},
    {item_string = "default:aspen_wood 32", price = 5, modes = all_modes},
    {item_string = "default:pine_tree 32", price = 5, modes = all_modes},
    {item_string = "default:pine_wood 32", price = 5, modes = all_modes},
    {item_string = "default:tree 32", price = 5, modes = all_modes},
    {item_string = "default:wood 32", price = 5, modes = all_modes},

    {item_string = "ctf_healing:heal_block", price = 100, modes = all_modes},
    {item_string = "ctf_landmine:landmine 20", price = 40, modes = all_modes},
    {item_string = "ctf_teams:door_steel 4", price = 20, modes = all_modes},
    {item_string = "ctf_map:spike 25", price = 20, modes = all_modes},
    {item_string = "xpanes:bar_flat 32", price = 10, modes = all_modes},

    --healing
    {item_string = "ctf_healing:medkit", price = 20, modes = all_modes},
    {item_string = "easter_egg:egg", price = 25, modes = all_modes},
    {item_string = "ctf_healing:bandage", price = 15, modes = all_modes},
    {item_string = "ctf_map:apple 32", price = 40, modes = all_modes},
    {item_string = "farming:bread 16", price = 95, modes = all_modes},
    --diamond
    --{item_string = "ctf_melee:sword_diamond", price = 40, modes = all_modes},
    {item_string = "default:pick_diamond", price = 50, modes = all_modes},
    {item_string = "default:axe_diamond", price = 60, modes = all_modes},
    {item_string = "default:shovel_diamond", price = 25, modes = all_modes},
    --mese
    --{item_string = "ctf_melee:sword_mese", price = 40, modes = all_modes},
    {item_string = "default:pick_mese", price = 30, modes = all_modes},
    {item_string = "default:axe_mese", price = 35, modes = all_modes},
    {item_string = "default:shovel_mese", price = 20, modes = all_modes},
    --steel
    --{item_string = "ctf_melee:sword_steel", price = 40, modes = all_modes},
    {item_string = "default:pick_steel", price = 15, modes = all_modes},
    {item_string = "default:axe_steel", price = 10, modes = all_modes},
    {item_string = "default:shovel_steel", price = 5, modes = all_modes},
    --weapons
    {item_string = "ctf_ranged:sniper_magnum_loaded", price = 120, modes = all_modes},
    {item_string = "ctf_ranged:shotgun_loaded", price = 120, modes = all_modes},
    {item_string = "ctf_ranged:assault_rifle_loaded", price = 50, modes = all_modes},
    {item_string = "ctf_ranged:rifle_loaded", price = 40, modes = all_modes},
    {item_string = "ctf_ranged:pistol_loaded", price = 10, modes = all_modes},
    --nice to have
    {item_string = "ctf_ranged:ammo 5", price = 15, modes = all_modes},
    {item_string = "grenades:frag", price = 25, modes = all_modes},
    {item_string = "wind_charges:wind_charge 32", price = 30, modes = all_modes},
    {item_string = "grenades:poison", price = 25, modes = all_modes},
    {item_string = "grenades:smoke", price = 15, modes = all_modes},
}

local players_is_dev_mode = {}
local players_scroll = {}

local function show_shop_formspec(player_name)
    if type(players_coins[player_name]) ~= "number" then
        players_coins[player_name] = start_coin_amount
    end

    if not minetest.check_player_privs(player_name, {dev = true}) then
        players_is_dev_mode[player_name] = nil
    end

    local coins = players_coins[player_name]

    local formspec = {
        "formspec_version[4]",
        "size[11,12]",
        "bgcolor[#1e1e1e;true]",
        "box[0,0;11,1.2;#2d2d2d]",

        "hypertext[0.4,0.15;10,1;title;<center><style size=25 color=#FFD700><b>CTF Shop</b></style></center>]",
        "hypertext[0.4,0.85;10,1;info;<style size=14 color=#CCCCCC>Browse items and buy them with coins.</style>]",

        "hypertext[7.95,0.6;2.2,1;coins;<right><style size=18 color=#FFD700><b>"
            .. minetest.formspec_escape(tostring(coins))
            .. "</b></style></right>]",
        "image[10.1,0.45;0.7,0.7;ctf_shop_coin.png]"
    }

    -- Dev mode checkbox
    if minetest.check_player_privs(player_name, {dev = true}) then
        table.insert(formspec,
            "checkbox[0.4,0.85;dev_mode_check;Developer Test Mode;" ..
            tostring(players_is_dev_mode[player_name] == true) .. "]"
        )
    end

    local current_mode = ctf_modebase.current_mode
    local current_y = 0

    local container_width = 10.3
    local container_height = 9.8
    local scrollbar_width = 0.25
    local y_size = 0.9

    table.insert(formspec,
        "scrollbar[10.7,2.0;" .. scrollbar_width .. "," .. container_height ..
        ";vertical;item_scrollbar;" .. (players_scroll[player_name] or "0") .. "]"
    )

    table.insert(formspec,
        "scroll_container[0.4,2.0;" .. container_width .. "," .. container_height ..
        ";item_scrollbar;vertical;0.1;0.2]"
    )

    -- Items
    for shop_item_id, shop_item in ipairs(shop_items) do
        if contains(shop_item.modes, current_mode) then

            table.insert(formspec,
                "item_image[0," .. current_y .. ";" .. y_size .. "," .. y_size ..
                ";" .. shop_item.item_string .. "]"
            )

            table.insert(formspec,
                "button[9," .. current_y ..
                ";1.2,0.9;buy_item_button_" .. shop_item_id .. ";Buy]"
            )

            table.insert(formspec,
                "hypertext[3.2," .. current_y+0.2 .. ";4,1;price;<style color=#CCCCCC>Price: " ..
                minetest.formspec_escape(tostring(shop_item.price)) .. "</style>]"
            )

            table.insert(formspec,
                "image[5.8," .. (current_y+0.15) ..
                ";0.55,0.55;ctf_shop_coin.png]"
            )

            current_y = current_y + y_size + 0.15
        end
    end

    table.insert(formspec, "scroll_container_end[]")

    table.insert(formspec, "button_exit[0.4,11.0;10.3,0.9;close_button;Close]")

    minetest.show_formspec(player_name, "ctf_shop:shop_formspec", table.concat(formspec))
end

minetest.register_on_player_receive_fields(function(player, formname, fields)
    if formname ~= "ctf_shop:shop_formspec" then
        return
    end
    if minetest.settings:get_bool("enable_ctf_shop", true) ~= true then
        return
    end
    local player_name = player:get_player_name()
    if type(players_coins[player_name]) ~= "number" then
        players_coins[player_name] = start_coin_amount
    end

    if fields.dev_mode_check then
        players_is_dev_mode[player_name] = (fields.dev_mode_check == "true" and minetest.check_player_privs(player_name, {dev = true}))
        if players_is_dev_mode[player_name] then
            minetest.chat_send_player(player_name, "NOTE: Don't use the Developer Test Mode in regular matches. It is only there for debugging purposes.")
        end
    end

    if fields.item_scrollbar then
        local scroll_value = fields.item_scrollbar:match("^CHG:(%d+)$")
        if scroll_value then
            players_scroll[player_name] = scroll_value
        end
    end

    if minetest.check_player_privs(player_name, {dev = true}) ~= true then
        players_is_dev_mode[player_name] = nil
    end

    for field, field_value in pairs(fields) do
        local shop_item_id = field:match("^buy_item_button_(%d+)$")
		if shop_item_id then
			shop_item_id = tonumber(shop_item_id)
            if type(shop_items[shop_item_id]) == "table" then
                if (players_coins[player_name] >= shop_items[shop_item_id].price) or players_is_dev_mode[player_name] then
                    local player_inventory = player:get_inventory()
                    player_inventory:add_item("main", shop_items[shop_item_id].item_string)
                    if players_is_dev_mode[player_name] ~= true then
                        players_coins[player_name] = players_coins[player_name] - shop_items[shop_item_id].price
                    end
                    show_shop_formspec(player_name)
                else
                    minetest.chat_send_player(player_name, "You don't have enough shop coins.")
                end
            end
		end
    end
end)

ctf_api.register_on_new_match(function()
    if minetest.settings:get_bool("enable_ctf_shop", true) ~= true then
        return
    end
    players_coins = {}
    players_scroll = {}
    minetest.after(3, function ()
        local team_player_names = ctf_teams.get_all_team_players()
        for _, player_name in ipairs(team_player_names) do
            local player = minetest.get_player_by_name(player_name)
            if player and ctf_settings.get(player, "ctf_shop:automatic_shop_display") == "true" then
                show_shop_formspec(player_name)
            end
        end
        core.chat_send_all(core.colorize("#f49200", "You can disable automatic shop display in the settings."))
    end)
end)

minetest.register_chatcommand("shop", {
	description = "Open the CTF Shop",
	privs = {interact = true},
	func = function(player_name)
        players_scroll[player_name] = nil
        if minetest.settings:get_bool("enable_ctf_shop", true) ~= true then
            return false, "The Shop is disabled."
        end

		show_shop_formspec(player_name)
		return true, "Opened the shop."
	end,
})

ctf_shop.shop_items = shop_items
ctf_shop.show_shop_formspec = show_shop_formspec
