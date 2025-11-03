-- In your mod's global scope, register the detached inventories table
inventory_admin.detached_inventories = {}

function handle_player_inventory(admin_name, target_player_name)
    inventory_admin.setup_detached_inventory(target_player_name)
    inventory_admin.sync_player_to_detached_inventory(target_player_name)
    core.show_formspec(admin_name, "inventory_admin:player_inventory",
        inventory_admin.get_player_inventory_formspec(target_player_name, admin_name))
    return true, "Showing inventory of " .. target_player_name
end

function handle_enderchest_inventory(admin_name, target_player_name)
    if inventory_admin.utils.is_mineclone2() then
        core.show_formspec(admin_name, "inventory_admin:enderchest_inventory",
            inventory_admin.get_enderchest_inventory_formspec(target_player_name))
        return true, "Showing enderchest inventory of " .. target_player_name
    else
        return false, "Enderchest inventory is not available in this game."
    end
end

-- Modify the command_inventory function to handle the new parameters
function inventory_admin.command_inventory(name, param)
    local player = core.get_player_by_name(name)
    if not player then
        return false, "You need to be online to use this command."
    end
    local args = param:split(" ")

    if inventory_admin.utils.is_mineclone2() then
        -- Handle command logic for MineClone2
        if #args < 2 then
            return false, "Usage: /invmanage <type> <player_name> in MineClone2"
        end

        local type, target_player_name = unpack(args)

        if type ~= "player" and type ~= "ender" then
            return false, "Invalid type. Use 'player' or 'ender'."
        end

        local target_player = core.get_player_by_name(target_player_name)
        if not target_player then
            return false, "Target player not found."
        end

        if type == "player" then
            -- Handle player inventory
            return handle_player_inventory(name, target_player_name)
        elseif type == "ender" then
            -- Handle enderchest inventory
            return handle_enderchest_inventory(name, target_player_name)
        end
    else
        -- Handle command logic for non-MineClone2 (e.g., minetest_game)
        if param:trim() == "" or #args > 1 then
            return false, "Usage: /invmanage <player_name>"
        end

        return handle_player_inventory(name, param:trim())
    end
end
