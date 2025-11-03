local S = core.get_translator("mcl_chests")
local F = core.formspec_escape
local C = core.colorize


-- Get the formspec for the inventory based on the game
function inventory_admin.get_player_inventory_formspec(target_player_name, admin_name)
    if inventory_admin.utils.is_mineclone2() then
        -- MineClone2 formspec
        local formspec = {
            "formspec_version[4]",
            "size[11.75,13]",  -- Adjust the height to accommodate the spacing

            -- Title for the target player's inventory
            "label[0.375,0.375;", core.formspec_escape(target_player_name .. "'s Inventory"), "]",

            -- Slot backgrounds for the target player's main inventory excluding the hotbar
            mcl_formspec.get_itemslot_bg_v4(0.375, 1, 9, 3),

            -- Slot list for the target player's main inventory excluding the hotbar
            "list[detached:" .. target_player_name .. "_inventory;main;0.375,1;9,3;9]",

            -- Slot background for the target player's hotbar, placed at the bottom
            mcl_formspec.get_itemslot_bg_v4(0.375, 5, 9, 1),

            -- Slot list for the target player's hotbar
            "list[detached:" .. target_player_name .. "_inventory;main;0.375,5;9,1;0]",

            -- Title for the admin's inventory, moved further down to create space
            "label[0.375,6.5;Your Inventory]",

            -- Slot backgrounds for the admin player's main inventory excluding the hotbar
            mcl_formspec.get_itemslot_bg_v4(0.375, 7, 9, 3),

            -- Slot list for the admin player's main inventory excluding the hotbar
            "list[current_player;main;0.375,7;9,3;9]",

            -- Slot background for the admin player's hotbar, placed further down with spacing similar to the singleplayer's hotbar
            mcl_formspec.get_itemslot_bg_v4(0.375, 11, 9, 1),

            -- Slot list for the admin player's hotbar, with adjusted Y-coordinate for correct spacing
            "list[current_player;main;0.375,11;9,1;0]",

            -- Listrings to allow moving items between the target's and admin's inventories
            "listring[detached:" .. target_player_name .. "_inventory;main]",
            "listring[current_player;main]",
        }

        return table.concat(formspec)
    else
        -- minetest_game formspec
        local formspec = {
            "size[8,10]",  -- Width of 8 slots, and enough height to accommodate all slots and labels

            -- Title for the target player's inventory
            "label[0.5,0;", core.formspec_escape(target_player_name .. "'s Inventory"), "]",

            -- Singleplayer's complete inventory, including the hotbar in one block
            "list[detached:" .. target_player_name .. "_inventory;main;0,0.5;8,4;]",  -- 8 slots per row, 4 rows in total

            -- Title for the admin's inventory
            "label[0.5,5.5;Your Inventory]",

            -- Admin's main inventory excluding the hotbar
            "list[current_player;main;0,6;8,3;8]",  -- 3 rows of 8 slots each, starting after the hotbar

            -- Admin's hotbar visually separated
            "list[current_player;main;0,9.5;8,1;0]",  -- The hotbar with 8 slots

            -- Listrings for item movement between the inventories
            "listring[detached:" .. target_player_name .. "_inventory;main]",
            "listring[current_player;main]",
        }

        return table.concat(formspec)
    end
end

function inventory_admin.get_enderchest_inventory_formspec(target_player_name)
    local formspec_ender_chest = {
        "formspec_version[4]",
        "size[11.75,10.425]",
        "label[0.375,0.375;", F(C(mcl_formspec.label_color, target_player_name.."'s "..S("Ender Chest"))) .. "]",
        mcl_formspec.get_itemslot_bg_v4(0.375, 0.75, 9, 3),
        "list[player:" .. target_player_name .. ";enderchest;0.375,0.75;9,3;]",  -- Access the target player's enderchest
        "label[0.375,4.7;", F(C(mcl_formspec.label_color, S("Inventory"))) .. "]",
        mcl_formspec.get_itemslot_bg_v4(0.375, 5.1, 9, 3),
        "list[current_player;main;0.375,5.1;9,3;9]",
        mcl_formspec.get_itemslot_bg_v4(0.375, 9.05, 9, 1),
        "list[current_player;main;0.375,9.05;9,1;]",
        "listring[player:" .. target_player_name .. ";enderchest]",
        "listring[current_player;main]",
    }
    return table.concat(formspec_ender_chest)
end
