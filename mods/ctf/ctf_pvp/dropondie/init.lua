dropondie = {}

local function drop_list(pos, player, list)
	local vel = player:get_velocity()
	local pname = player:get_player_name()
	local is_player = pname ~= ""
	local inv = player:get_inventory()
	for _, item in ipairs(inv:get_list(list)) do
		if core.registered_items[item:get_name()].stack_max == 1 then
			if is_player then
				local meta = item:get_meta()
				meta:set_string("dropped_by", pname)
			end
		end

		local obj = core.add_item(pos, item)
		if obj then
			local random_velocity = {
				x = math.random(-1, 1),
				y = 5,
				z = math.random(-1, 1),
			}

			local final_velocity = vector.add(vector.divide(vel, 2), random_velocity)

			obj:set_velocity(final_velocity)
		end
	end

	inv:set_list(list, {})
end

function dropondie.drop_all(player)
	if not ctf_teams.get(player) then
		return
	end

	ctf_modebase.player.remove_bound_items(player)
	ctf_modebase.player.remove_initial_stuff(player)

	local pos = player:get_pos()
	pos.y = math.floor(pos.y + 0.5)

	drop_list(pos, player, "main")
end

if ctf_core.settings.server_mode ~= "mapedit" then
	core.register_on_dieplayer(dropondie.drop_all)
	core.register_on_leaveplayer(dropondie.drop_all)
end
