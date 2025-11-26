if type(ctf_api) ~= "table" or type(ctf_teams) ~= "table" or type(ctf_modebase) ~= "table" or type(ctf_settings) ~= "table" then
    return
end

local function contains(tbl, val)
    if type(tbl) ~= "table" then
        return false
    end
    for _, v in pairs(tbl) do
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

local modes_all = ctf_modebase.modelist
local modes_without_nade_fight = {"chaos", "classes", "classic", "rush"}

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
    --{item_string = "default:steelblock 32", price = 40, modes = modes_all},
    --{item_string = "default:mese 64", price = 40, modes = modes_all},
    --{item_string = "default:obsidian 32", price = 20, modes = modes_all},
    {item_string = "ctf_map:reinforced_cobble 20", price = 20, modes = modes_all},
    {item_string = "ctf_map:damage_cobble 20", price = 15, modes = modes_all},
    {item_string = "default:stonebrick 64", price = 10, modes = modes_all},
    {item_string = "default:obsidian_glass 32", price = 5, modes = modes_all},
    {item_string = "xpanes:obsidian_pane_flat 32", price = 5, modes = modes_all},

    {item_string = "default:acacia_tree 10", price = 5, modes = modes_all},
    {item_string = "default:acacia_wood 32", price = 5, modes = modes_all},
    {item_string = "default:aspen_tree 10", price = 5, modes = modes_all},
    {item_string = "default:aspen_wood 32", price = 5, modes = modes_all},
    {item_string = "default:pine_tree 10", price = 5, modes = modes_all},
    {item_string = "default:pine_wood 32", price = 5, modes = modes_all},
    {item_string = "default:tree 10", price = 5, modes = modes_all},
    {item_string = "default:wood 32", price = 5, modes = modes_all},

    {item_string = "ctf_healing:heal_block", price = 120, modes = modes_all},
    {item_string = "ctf_landmine:landmine 10", price = 40, modes = modes_all},
    {item_string = "ctf_teams:door_steel 4", price = 20, modes = modes_all},
    {item_string = "ctf_map:spike 20", price = 20, modes = modes_all},
    {item_string = "xpanes:bar_flat 32", price = 10, modes = modes_all},

    --healing
    {item_string = "ctf_healing:medkit", price = 25, modes = modes_all},
    {item_string = "ctf_healing:bandage", price = 25, modes = modes_all},
    {item_string = "default:apple 15", price = 40, modes = modes_without_nade_fight},
    {item_string = "farming:bread 12", price = 60, modes = modes_all},
    --diamond
    --{item_string = "ctf_melee:sword_diamond", price = 40, modes = modes_all},
    {item_string = "default:pick_diamond", price = 50, modes = modes_all},
    {item_string = "default:axe_diamond", price = 60, modes = modes_all},
    {item_string = "default:shovel_diamond", price = 25, modes = modes_all},
    --mese
    --{item_string = "ctf_melee:sword_mese", price = 40, modes = modes_all},
    {item_string = "default:pick_mese", price = 30, modes = modes_all},
    {item_string = "default:axe_mese", price = 35, modes = modes_all},
    {item_string = "default:shovel_mese", price = 20, modes = modes_all},
    --steel
    --{item_string = "ctf_melee:sword_steel", price = 40, modes = modes_all},
    {item_string = "default:pick_steel", price = 15, modes = modes_all},
    {item_string = "default:axe_steel", price = 10, modes = modes_all},
    {item_string = "default:shovel_steel", price = 5, modes = modes_all},
    --weapons
    --{item_string = "ctf_ranged:sniper_magnum_loaded", price = 120, modes = modes_all},
    --{item_string = "ctf_ranged:shotgun_loaded", price = 120, modes = modes_all},
    {item_string = "ctf_ranged:assault_rifle_loaded", price = 60, modes = modes_all},
    {item_string = "ctf_ranged:rifle_loaded", price = 50, modes = modes_all},
    {item_string = "ctf_ranged:pistol_loaded", price = 15, modes = modes_all},
    --nice to have
    {item_string = "ctf_ranged:ammo 5", price = 15, modes = modes_all},
    {item_string = "grenades:frag", price = 25, modes = modes_all},
    {item_string = "wind_charges:wind_charge 15", price = 30, modes = modes_all},
    {item_string = "grenades:poison", price = 25, modes = modes_all},
    {item_string = "grenades:smoke", price = 15, modes = modes_all},
}

local max_items_per_page = 12

local players_is_dev_mode = {}
local players_last_page = {}

local function get_max_pages()
    local item_count = 0
    for _, item_entry_def in ipairs(shop_items) do
        if type(item_entry_def) == "table" then
            item_count = item_count + 1
        end
    end
    return math.ceil(item_count / max_items_per_page)
end

local function get_items_of_page(page, ctf_mode)
    local allowed = {}
    for idx, def in ipairs(shop_items) do
        if type(def) == "table" and type(def.modes) == "table" and contains(def.modes, ctf_mode) then
            table.insert(allowed, {index = idx, item = def})
        end
    end
    local page_shop_items = {}
    local start_index = ((page - 1) * max_items_per_page) + 1
    local end_index = page * max_items_per_page
    for i = start_index, end_index do
        local entry = allowed[i]
        if entry then
            page_shop_items[entry.index] = entry.item
        end
    end
    return page_shop_items
end

local function show_shop_formspec(player_name, page)
    local current_mode = ctf_modebase.current_mode
    if not current_mode then
        return
    end
    if type(page) ~= "number" then
        page = 1
    end
    local max_pages = get_max_pages()
    page = math.max(1, math.min(max_pages, page))
    players_last_page[player_name] = page

    if type(players_coins[player_name]) ~= "number" then
        players_coins[player_name] = start_coin_amount
    end

    if minetest.check_player_privs(player_name, {dev = true}) ~= true then
        players_is_dev_mode[player_name] = nil
    end

    local formspec_string = "formspec_version[4]size[8,12]label[0.3,0.4;Shop]" ..
                            "label[6.9,0.4;" .. players_coins[player_name] .. "]image[7.3,0.1;0.55,0.55;ctf_shop_coin.png]"

    if minetest.check_player_privs(player_name, {dev = true}) then
        formspec_string = formspec_string .. "checkbox[2.8,0.4;dev_mode_check;Developer Test Mode;" .. tostring(players_is_dev_mode[player_name] == true) .. "]"
    end

    local current_y = 0.9

	local y_size = 0.7

    for shop_item_id, shop_item in pairs(get_items_of_page(page, current_mode)) do
        formspec_string = formspec_string .. "item_image[0.3," .. current_y .. ";" .. y_size .. "," .. y_size .. ";" .. shop_item.item_string .. "]"--item image
        formspec_string = formspec_string .. "button[7.0," .. current_y .. ";" .. y_size .. "," .. y_size .. ";buy_item_button_" .. shop_item_id .. ";+]"
        formspec_string = formspec_string .. "label[3.7," .. current_y + 0.36 .. ";" .. shop_item.price .. "]"
        formspec_string = formspec_string .. "image[4.1," .. current_y + 0.075 .. ";0.55,0.55;ctf_shop_coin.png]"
        current_y = current_y + y_size + 0.1
    end

    formspec_string = formspec_string .. "label[3.85,10.6;" .. page .. "/" .. max_pages .. "]"
    formspec_string = formspec_string .. "button_exit[1.3,10.9;5.4,0.8;close_button;Close]"

    formspec_string = formspec_string .. "button[0.3,10.9;0.8,0.8;previous_page_button;<]"
    formspec_string = formspec_string .. "button[6.9,10.9;0.8,0.8;next_page_button;>]"
    minetest.show_formspec(player_name, "ctf_shop:shop_formspec", formspec_string)
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

    if fields.previous_page_button then
        show_shop_formspec(player_name, (players_last_page[player_name] or 1) - 1)
        return
    end

    if fields.next_page_button then
        show_shop_formspec(player_name, (players_last_page[player_name] or 1) + 1)
        return
    end

    if fields.dev_mode_check then
        players_is_dev_mode[player_name] = (fields.dev_mode_check == "true" and minetest.check_player_privs(player_name, {dev = true}))
        if players_is_dev_mode[player_name] then
            minetest.chat_send_player(player_name, "NOTE: Don't use the Developer Test Mode in regular matches. It is only there for debugging purposes.")
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
                    show_shop_formspec(player_name, (players_last_page[player_name] or 1))
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
    minetest.after(3, function ()
        local team_player_names = ctf_teams.get_all_team_players()
        for _, player_name in ipairs(team_player_names) do
            local player = minetest.get_player_by_name(player_name)
            if player and ctf_settings.get(player, "ctf_shop:automatic_shop_display") == "true" then
                show_shop_formspec(player_name, 1)
            end
        end
        core.chat_send_all(core.colorize("#f49200", "You can disable automatic shop display in the settings."))
    end)
end)

minetest.register_chatcommand("shop", {
	description = "Open the CTF Shop",
	privs = {interact = true},
	func = function(player_name)
        if minetest.settings:get_bool("enable_ctf_shop", true) ~= true then
            return false, "The Shop is disabled."
        end

		show_shop_formspec(player_name, 1)
		return true, "Opened the shop."
	end,
})

ctf_shop.shop_items = shop_items
ctf_shop.show_shop_formspec = show_shop_formspec
