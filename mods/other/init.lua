minetest.register_chatcommand("who", {
    description = "Liste des joueurs connectés",
    privs = {},  
    func = function(name)
        local players = minetest.get_connected_players()
        local player_names = {}
        for _, player in ipairs(players) do
            table.insert(player_names, player:get_player_name())
        end

        if #player_names > 0 then
            return true, "Joueurs connectés : " .. table.concat(player_names, ", ")
        else
            return true, "Aucun joueur connecté."
        end
    end,
})
