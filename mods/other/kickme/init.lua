minetest.register_chatcommand("kickme", {
	description = "Disconnect yourself",
	func = function(name)
		minetest.kick_player(name, "Disconnected by /kickme")
	end

})