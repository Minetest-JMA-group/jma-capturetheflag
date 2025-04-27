minetest.register_chatcommand("who", {
    description = "List of connected players",
    privs = {},  
    func = function(name)
        local players = minetest.get_connected_players()
        local player_names = {}
        for _, player in ipairs(players) do
            table.insert(player_names, player:get_player_name())
        end

        local player_count = #player_names 

        if player_count > 0 then
            return true, "There are " .. player_count .. " player(s) connected: " .. table.concat(player_names, ", ")
        else
            return true, "No players are connected."
        end
    end,
})
