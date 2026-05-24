-- Mapping between teams and available wool colors
local TEAM_WOOL_COLORS = {
	red = "wool:red",
	green = "wool:green",
	blue = "wool:blue",
	orange = "wool:orange",
	yellow = "wool:yellow",
	purple = "wool:violet",
}

-- Mapping between wool colors and white wool for digging
local WOOL_COLOR_TO_WHITE = {
	["wool:red"] = "wool:white",
	["wool:green"] = "wool:white",
	["wool:blue"] = "wool:white",
	["wool:orange"] = "wool:white",
	["wool:yellow"] = "wool:white",
	["wool:violet"] = "wool:white",
	["wool:pink"] = "wool:white",
	["wool:cyan"] = "wool:white",
	["wool:dark_grey"] = "wool:white",
	["wool:grey"] = "wool:white",
	["wool:black"] = "wool:white",
	["wool:dark_green"] = "wool:white",
	["wool:brown"] = "wool:white",
	["wool:magenta"] = "wool:white",
}

-- Override placement for wool:white to replace it with the team color
core.override_item("wool:white", {
	after_place_node = function(pos, placer, itemstack, pointed_thing)
		-- Check that the placer is a player
		if not placer then
			return
		end

		local player_name = placer:get_player_name()
		local team = ctf_teams.get(player_name)

		-- If the player has no team, keep the white wool
		if not team then
			return
		end

		-- Get the wool color corresponding to the team
		local team_wool_color = TEAM_WOOL_COLORS[team]
		if not team_wool_color then
			return
		end

		-- Get the node that was just placed
		local newnode = core.get_node(pos)

		-- Replace the wool:white node with the team color
		local new_wool_node = {name = team_wool_color, param1 = newnode.param1, param2 = newnode.param2}
		core.set_node(pos, new_wool_node)
	end
})

-- Override dig for all wool colors to return white wool instead
for wool_color, white_wool in pairs(WOOL_COLOR_TO_WHITE) do
	core.override_item(wool_color, {
		on_dig = function(pos, node, digger)
			-- Check that the digger is a player
			if not digger then
				return false
			end

			-- Remove the node
			core.remove_node(pos)

			-- Give the player white wool
			local inv = digger:get_inventory()
			inv:add_item("main", white_wool)

			return true
		end
	})
end