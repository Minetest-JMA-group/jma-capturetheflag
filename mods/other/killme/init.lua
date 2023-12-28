minetest.register_chatcommand("killme", {
	description = "Kill yourself to respawn",
	func = function(name, _)
		local player = minetest.get_player_by_name(name)
		if player then
			player:set_hp(0, name.." executed killme.")
		end
	end
})
