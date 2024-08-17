local timer
local spawn_interval = 60

local function spawn_giftbox()
	local spawn_amount = math.max(20, math.min(#minetest.get_connected_players(), 40))

	local vm = VoxelManip()
	local pos1, pos2 = vm:read_from_map(ctf_map.current_map.pos1, ctf_map.current_map.pos2)
	for _ = 1, spawn_amount do

		local rand_pos = vector.new(math.random(pos1.x, pos2.x), math.max(pos1.y, pos2.y), math.random(pos1.z, pos2.z))

		local air_nodes = 0
		for y_off = 1, 50 do
			local npos = vector.offset(rand_pos, 0, -y_off, 0)
			local node_name = vm:get_node_at(npos).name
			if node_name == "air" then
				air_nodes = air_nodes + 1
			end
			if air_nodes == 3 then
				minetest.add_entity(npos, "random_gifts:gift")
				break
			end
		end
	end
	timer = minetest.after(spawn_interval, spawn_giftbox)
end

function random_gifts.run_spawn_timer()
	timer = minetest.after(10, spawn_giftbox)
end

function random_gifts.stop_spawn_timer()
	if timer then
		timer:cancel()
	end
end
