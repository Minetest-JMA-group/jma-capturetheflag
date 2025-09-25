local S = core.get_translator(core.get_current_modname())

local landmines = {
	-- { x = ..., y = ..., z = ...}
}

local landmine_globalstep_counter = 0.0
local LANDMINE_COUNTER_THRESHOLD = 0.025

local function is_self_landmine(object_ref, pos)
	local meta = minetest.get_meta(pos)
	local team = meta:get_string("pteam")
	local placer = meta:get_string("placer")
	local pname = object_ref:get_player_name()
	if pname == "" then
		return nil -- the object ref is not a player
	end
	if pname == placer then
		return true -- it's self landmine
	end
	if ctf_teams.get(object_ref) == team then
		return true -- it's self landmine
	end

	return false -- it's someone else's landmine
end

local function landmine_explode(pos)
	local near_objs = minetest.get_objects_inside_radius(pos, 3)
	local meta = minetest.get_meta(pos)
	local placer = meta:get_string("placer")
	local placerobj = placer and minetest.get_player_by_name(placer)

	minetest.add_particlespawner({
		amount = 20,
		time = 0.5,
		minpos = vector.subtract(pos, 3),
		maxpos = vector.add(pos, 3),
		minvel = { x = 0, y = 5, z = 0 },
		maxvel = { x = 0, y = 7, z = 0 },
		minacc = { x = 0, y = 1, z = 0 },
		maxacc = { x = 0, y = 1, z = 0 },
		minexptime = 0.3,
		maxexptime = 0.6,
		minsize = 7,
		maxsize = 10,
		collisiondetection = true,
		collision_removal = false,
		vertical = false,
		texture = "grenades_smoke.png",
	})

	minetest.add_particle({
		pos = pos,
		velocity = { x = 0, y = 0, z = 0 },
		acceleration = { x = 0, y = 0, z = 0 },
		expirationtime = 0.3,
		size = 15,
		collisiondetection = false,
		collision_removal = false,
		object_collision = false,
		vertical = false,
		texture = "grenades_boom.png",
		glow = 10,
	})

	minetest.sound_play("ctf_landmine_explosion", {
		pos = pos,
		gain = 0.9,
		max_hear_distance = 16,
	})

	for _, obj in pairs(near_objs) do
		if is_self_landmine(obj, pos) == false then
			if placerobj then
				obj:punch(placerobj, 1, {
					damage_groups = {
						fleshy = 15,
						landmine = 1,
					},
				})
			else
				local chp = obj:get_hp()
				obj:set_hp(chp - 15)
			end
		end
	end
	minetest.remove_node(pos)
	for idx, pos_ in ipairs(landmines) do
		if pos_ == pos then
			table.remove(landmines, idx)
			break
		end
	end
end

minetest.register_node("ctf_landmine:landmine", {
	description = S("Landmine") .. "\n" .. S(
		"A trap that explodes when stepped on except for team mates."
	) .. "\n" .. S("Effective defensive tool for securing your base."),
	drawtype = "nodebox",
	tiles = {
		"ctf_landmine_landmine.png",
		"ctf_landmine_landmine.png^[transformFY",
	},
	inventory_image = "ctf_landmine_landmine.png",
	paramtype = "light",
	sunlight_propagates = true,
	walkable = true,
	groups = { cracky = 1, level = 2 },
	node_box = {
		type = "fixed",
		fixed = { -0.4375, -0.5000, -0.4375, 0.4375, -0.4750, 0.4375 },
	},
	selection_box = {
		type = "fixed",
		fixed = { -0.4375, -0.5000, -0.4375, 0.4375, -0.4750, 0.4375 },
	},
	on_place = function(itemstack, placer, pointed_thing)
		local pteam = ctf_teams.get(placer:get_player_name())

		if pteam then
			for flagteam, team in pairs(ctf_map.current_map.teams) do
				if
					pteam ~= flagteam
					and not ctf_modebase.flag_captured[flagteam]
					and team.flag_pos
				then
					local distance_from_flag =
						vector.distance(placer:get_pos(), team.flag_pos)
					if distance_from_flag < 15 then -- block landmine placement when closer than 15 nodes to the enemy flag
						hud_events.new(placer:get_player_name(), {
							text = S("You can't place landmine so close to a flag"),
							color = "warning",
							quick = true,
						})
						return nil
					end
				end
			end
		end

		return minetest.item_place(itemstack, placer, pointed_thing)
	end,
	after_place_node = function(pos, placer, itemstack, pointed_thing)
		local meta = minetest.get_meta(pos)
		local name = placer:get_player_name()
		local pteam = ctf_teams.get(placer)

		meta:set_string("placer", name)
		meta:set_string("pteam", pteam)
		table.insert(landmines, pos)
	end,
	on_punch = function(pos, _node, puncher, pointed_thing)
		if is_self_landmine(puncher, pos) == false then
			landmine_explode(pos)
		end
	end,
	on_destruct = function(pos)
		for idx, pos_ in ipairs(landmines) do
			if pos_ == pos then
				table.remove(landmines, idx)
				break
			end
		end
	end,
})

minetest.register_globalstep(function(dtime)
	if #landmines == 0 then
		return
	end
	landmine_globalstep_counter = landmine_globalstep_counter + dtime
	if landmine_globalstep_counter < LANDMINE_COUNTER_THRESHOLD then
		return
	end
	landmine_globalstep_counter = 0.0
	for _idx, pos in pairs(landmines) do
		local near_objs = minetest.get_objects_in_area({
			x = pos.x - 0.5,
			y = pos.y - 0.5,
			z = pos.z - 0.5,
		}, {
			x = pos.x + 0.5,
			y = pos.y - 0.3,
			z = pos.z + 0.5,
		})
		local must_explode = false
		for _, obj in pairs(near_objs) do
			if is_self_landmine(obj, pos) == false then
				must_explode = true
				break
			end
		end
		if must_explode then
			landmine_explode(pos)
		end
	end
end)

ctf_api.register_on_match_end(function()
	landmines = {}
end)
