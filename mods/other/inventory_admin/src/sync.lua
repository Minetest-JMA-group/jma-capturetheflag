function inventory_admin.setup_detached_inventory(target_player_name)
    -- Create a detached inventory if it does not exist
    if not inventory_admin.detached_inventories[target_player_name] then
        inventory_admin.detached_inventories[target_player_name] = core.create_detached_inventory(target_player_name .. "_inventory", {
            -- Define the callback functions for inventory actions
            on_put = function(inv, listname, index, stack, player)
                -- Sync the changes from the detached inventory to the player's inventory when items are put
                inventory_admin.sync_inventory_to_player(target_player_name, listname, index, stack)
            end,
            on_take = function(inv, listname, index, stack, player)
                -- Sync the changes from the detached inventory to the player's inventory when items are taken
                inventory_admin.sync_inventory_to_player(target_player_name, listname, index, nil)
            end,
            on_move = function(inv, from_list, from_index, to_list, to_index, count, player)
                -- Sync the entire inventory when items are moved within the detached inventory
                inventory_admin.sync_inventory_to_player(target_player_name)
            end,
        })
        
        -- Set the size of the inventory (e.g., main and hotbar are typically 9 slots each)
        if inventory_admin.utils.is_mineclone2() then
            inventory_admin.detached_inventories[target_player_name]:set_size("main", 36) -- Adjust size accordingly
            inventory_admin.detached_inventories[target_player_name]:set_size("hotbar", 9) -- Adjust size accordingly
        else
            inventory_admin.detached_inventories[target_player_name]:set_size("main", 32) -- Adjust size accordingly
            inventory_admin.detached_inventories[target_player_name]:set_size("hotbar", 8) -- Adjust size accordingly
        end
    end

    -- Fill the detached inventory with the player's inventory items
    inventory_admin.sync_player_to_detached_inventory(target_player_name)
end

function inventory_admin.sync_player_to_detached_inventory(target_player_name)
    local player = core.get_player_by_name(target_player_name)
    if not player then
        core.log("error", "Player not found: " .. target_player_name)
        return
    end

    local player_inv = player:get_inventory()
    local detached_inv = inventory_admin.detached_inventories[target_player_name]

    -- Check if the detached inventory has been set up
    if not detached_inv then
        core.log("error", "Detached inventory not found for player: " .. target_player_name)
        return
    end

    -- Copy the player's inventory into the detached inventory, including the hotbar
    for i = 1, player_inv:get_size("main") do
        detached_inv:set_stack("main", i, player_inv:get_stack("main", i))
    end
end




function inventory_admin.sync_inventory_to_player(target_player_name, listname, index, stack)
    local player = core.get_player_by_name(target_player_name)
    if not player then
        core.log("error", "Player not found: " .. target_player_name)
        return
    end

    local player_inv = player:get_inventory()
    local detached_inv = inventory_admin.detached_inventories[target_player_name]

    -- If specific listname and index are provided, only sync that particular slot
    if listname and index then
        if stack then
            -- The stack is provided, so we update the slot with the new stack
            player_inv:set_stack(listname, index, stack)
        else
            -- If stack is nil, it means an item was taken out, so we set the slot to be empty
            player_inv:set_stack(listname, index, ItemStack(nil))
        end
    else
        -- Sync the entire inventory, which includes the hotbar since it's part of 'main'
        for i = 1, detached_inv:get_size("main") do
            player_inv:set_stack("main", i, detached_inv:get_stack("main", i))
        end
    end
end



