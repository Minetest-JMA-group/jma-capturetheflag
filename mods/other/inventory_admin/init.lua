local modpath = minetest.get_modpath("inventory_admin")
local srcpath = modpath .. "/src/"
inventory_admin = {}

dofile(srcpath .. "utils.lua")
dofile(srcpath .. "formspecs.lua")
dofile(srcpath .. "sync.lua")
dofile(srcpath .. "command.lua")

-- Register the invmanage priv
minetest.register_privilege("invmanage", {
    description = "Allows viewing and manageing of the inventory of other players",
    give_to_singleplayer = false,
})
local inv_cmd_def = {
    description = "View the inventory of another player",
    privs = {invmanage = true},
    func = inventory_admin.command_inventory,
}

if inventory_admin.utils.is_mineclone2() then
  inv_cmd_def.params = "<type> <playername>"
else
  inv_cmd_def.params = "<playername>"
end

-- Register the /inventory command
minetest.register_chatcommand("invmanage", inv_cmd_def)


-- On join player setup detached inventory
minetest.register_on_joinplayer(function(player)
    inventory_admin.setup_detached_inventory(player:get_player_name())
end)

-- Sync function that checks for changes in the player's inventory
-- and updates the detached inventory accordingly.
local function sync_inventories()
    for _, player in ipairs(minetest.get_connected_players()) do
        local player_name = player:get_player_name()
        --minetest.log("action", "Syncing inventory of player: " .. player_name)
        inventory_admin.sync_player_to_detached_inventory(player_name)
    end
end

-- Register a globalstep to periodically check for inventory changes.
local timer = 0

-- Register a globalstep to periodically check for inventory changes.
minetest.register_globalstep(function(dtime)
    -- Interval in seconds to update the inventories, e.g., every 1 second.
    local interval = 1

    -- Accumulate elapsed time
    timer = timer + dtime
    if timer >= interval then
        -- Sync inventories
        sync_inventories()

        -- Reset the timer after syncing
        timer = 0
    end
end)
