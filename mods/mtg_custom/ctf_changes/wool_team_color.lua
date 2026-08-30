-- Mapping between teams and available wool colors
local TEAM_WOOL_COLORS = {
	red = "wool:red",
	green = "wool:green",
	blue = "wool:blue",
	orange = "wool:orange",
	yellow = "wool:yellow",
	purple = "wool:violet",
}

local WOOL_COLORS = {
	"wool:red",
	"wool:green",
	"wool:blue",
	"wool:orange",
	"wool:yellow",
	"wool:violet",
	"wool:pink",
	"wool:cyan",
	"wool:dark_grey",
	"wool:grey",
	"wool:black",
	"wool:dark_green",
	"wool:brown",
	"wool:magenta",
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
		local new_wool_node =
			{ name = team_wool_color, param1 = newnode.param1, param2 = newnode.param2 }
		core.set_node(pos, new_wool_node)
	end,
})

-- Override drop for all wool colors to return white wool instead
for _, wool_color in ipairs(WOOL_COLORS) do
	core.override_item(wool_color, {
		drop = "wool:white",
	})
end
