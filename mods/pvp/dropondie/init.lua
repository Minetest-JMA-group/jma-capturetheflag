dropondie = {}

local function drop_list(pos, vel, inv, list)
	for _, item in ipairs(inv:get_list(list)) do
		local obj = minetest.add_item(pos, item)
		if obj then
			local random_velocity = {
				x = math.random(-1, 1),
				y = 5,
				z = math.random(-1, 1)
			}

			local final_velocity = vector.add(vector.divide(vel, 2), random_velocity)

			obj:set_velocity(final_velocity)
		end
	end

	inv:set_list(list, {})
end

function dropondie.drop_all(player)
	if not ctf_teams.get(player) then return end

	ctf_modebase.player.remove_bound_items(player)
	ctf_modebase.player.remove_initial_stuff(player)

	local pos = player:get_pos()
	pos.y = math.floor(pos.y + 0.5)

	drop_list(pos, player:get_velocity(), player:get_inventory(), "main")
end

if ctf_core.settings.server_mode ~= "mapedit" then
	minetest.register_on_dieplayer(dropondie.drop_all)
	minetest.register_on_leaveplayer(dropondie.drop_all)
end
