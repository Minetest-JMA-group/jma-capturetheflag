minetest.register_chatcommand("who", {
    description = "List of connected players",
    privs = {},  
    func = function(name)
        local players = minetest.get_connected_players()
        local player_names = {}
        for _, player in ipairs(players) do
            table.insert(player_names, player:get_player_name())
        end

        if #player_names > 0 then
            return true, "Connected players : " .. table.concat(player_names, ", ")
        else
            return true, "No players connected."
        end
    end,
})
