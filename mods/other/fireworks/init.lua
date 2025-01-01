do
	local day, month = os.date("*t").day, os.date("*t").month
	if month > 1 or (month == 1 and day >= 3) then return end
end

fireworks = {
	colors = {
		{"red", "Red"},
		{"orange", "Orange"},
		{"violet", "Violet"},
		{"green", "Green"},
		{"pink", "Pink"},
	}
}

local random_items = {
	{itemname = "easter_egg:egg", chance = 2, amount = 1},
	{itemname = "default:cobble", chance = 40, amount = 30},

	{itemname = "default:dirt", chance = 41, amount = 30},
	{itemname = "default:apple", chance = 20, amount = 8},
	{itemname = "default:diamond", chance = 5, amount = 2},
	{itemname = "default:torch", chance = 42, amount = 15},
	{itemname = "ctf_map:damage_cobble", chance = 25, amount = 30},
	{itemname = "default:obsidian", chance = 22, amount = 10},

	{itemname = "rocket_launcher:launcher", chance = 12, amount = 1},
	{itemname = "rocket_launcher:rocket", chance = 13, amount = 5},

	{itemname = "fireworks:red", chance = 2, amount = 2},
	{itemname = "ctf_landmine:landmine", chance = 12, amount = 5}
}

ctf_api.register_on_new_match(function()
	if ctf_modebase.current_mode ~= "chaos" then
		random_gifts.set_items(random_items)
	end
end)

ctf_api.register_on_match_end(function()
	random_gifts.set_items({})
end)

local function spawn_giftbox(pos)
	minetest.add_entity(pos, "random_gifts:gift")
end

local function fireworks_boom(pos, firework_name)
	minetest.sound_play("fireworks_explosion", {
		pos = pos,
		max_hear_distance = 70,
		gain = math.random(5, 10)
	})

	minetest.add_particlespawner({
		amount = 150,
		time = 0.001,
		minpos = pos,
		maxpos = pos,
		minvel = vector.new(-4, - 4, - 4),
		maxvel = vector.new(4, 4, 4),
		minacc = {x = 0, y = -0.5, z = 0},
		maxacc = {x = 0, y = -1, z = 0},
		minexptime = 2,
		maxexptime = 3,
		minsize = 2,
		maxsize = 3,
		collisiondetection = true,
		vertical = false,
		glow = 8,
		texture = "firework_sparks_"..firework_name..".png",
	})
	minetest.add_particlespawner({
		amount = 100,
		time = 0.001,
		minpos = pos,
		maxpos = pos,
		minvel = vector.new(-4, -4, -4),
		maxvel = vector.new(4, 4, 4),
		minacc = {x = 0, y = -0.5, z = 0},
		maxacc = {x = 0, y = -1, z = 0},
		minexptime = 2,
		maxexptime = 3,
		minsize = 2,
		maxsize = 3,
		collisiondetection = true,
		vertical = false,
		glow = 10,
		texture = "firework_sparks_blue.png^[multiply:" .. random_gifts.random_rgb_color() .. ":100",
	})

end

for _, i in pairs(fireworks.colors) do
	minetest.register_node("fireworks:"..i[1], {
		description = i[2].." Fireworks",
		tiles = {"firework_"..i[1]..".png"},
		groups = {dig_immediate = 1},
		drawtype = "plantlike",
		paramtype = "light",
		selection_box = {
			type = "fixed",
			fixed = { - 2 / 16, - 0.5, - 2 / 16, 2 / 16, 3 / 16, 2 / 16},
		},
		on_punch = function(pos, node, puncher, pointed_thing)
			local wielded = puncher:get_wielded_item():get_name()
			if wielded == "default:torch" or wielded == "fire:flint_and_steel" then
				minetest.sound_play("fireworks_launch", {
					pos = pos,
					max_hear_distance = 10,
					gain = 8.0
				})

				minetest.add_particlespawner({
					amount = 5,
					time = 0.001,
					minpos = pos,
					maxpos = pos,
					minvel = vector.new(-1, - 1, - 1),
					maxvel = vector.new(1, 1, 1),
					minacc = {x = 0, y = -0.5, z = 0},
					maxacc = {x = 0, y = -1, z = 0},
					minexptime = 1,
					maxexptime = 2,
					minsize = 2,
					maxsize = 3,
					collisiondetection = true,
					vertical = false,
					glow = 5,
					texture = "random_gifts_spark.png^[multiply:yellow"
				})

				minetest.after(0.2, function()
					if minetest.get_node(pos).name:sub(1, 9) == "fireworks" then
						minetest.remove_node(pos)
						local entity = minetest.add_entity(pos, "fireworks:rocket")
						entity:set_properties({textures = {"firework_"..i[1]..".png"}})
						local luaent = entity:get_luaentity()
						luaent.firework_name = i[1]
						luaent.player_name = puncher:get_player_name()
						entity:add_velocity(vector.new(0, math.random(10, 13), 0))
					end
				end)
				return
			end
			return minetest.dig_node(pos, puncher)
		end,
		sounds = default.node_sound_stone_defaults(),
	})
end


minetest.register_entity("fireworks:rocket", {
	initial_properties = {
		armor_groups = {immortal = true},
		physical = true,
		visual = "upright_sprite",
		visual_size = {x=1, y=1,},
		textures = {},
		pointable = false,
		collisionbox = {-0.25,-0.25,-0.25,0.25,0.25,0.25},
		collide_with_objects = false,
		static_save = false,
	},
	timer = 0,
	on_activate = function(self, staticdata, dtime_s)
		self.expiration_time = math.random(1, 4)
	end,
	on_step = function(self, dtime, moveresult)
		self.timer = self.timer + dtime
		local pos = self.object:get_pos()
		if not pos then return end

		minetest.add_particle({
			pos = pos,
			velocity = {x=math.random(-1,1),y=math.random(-1,1),z=math.random(-1,1)},
			expirationtime = 1.9,
			size = 3,
			collisiondetection = false,
			vertical = false,
			texture = "tnt_smoke.png",
			glow = 15})

		if self.timer >= self.expiration_time then
			fireworks_boom(pos, self.firework_name)
			self.object:remove()
			new_year_event.add_firework_count(self.player_name)
			if math.random(1, 4) == 1 then
				spawn_giftbox(pos)
			end
			return
		end

		if self.timer > 0.1 then
			local objs = minetest.get_objects_inside_radius({x = pos.x, y = pos.y - 1, z = pos.z}, 1.3)
			for k, obj in pairs(objs) do
				local prop = obj
				if prop then
					if obj:is_player() then
						local accel = vector.new(math.random(0, 1), self.object:get_velocity().y / 8, math.random(0, 1))
						obj:add_velocity(accel)
					end
				end
			end
		end

		if moveresult.collides then
			for _, c in ipairs(moveresult.collisions) do
				if c.type == "node" then
					fireworks_boom(pos, self.firework_name)
					new_year_event.add_firework_count(self.player_name)
					self.object:remove()
				end
			end
		end
	end
})


dofile(minetest.get_modpath("fireworks") .. "/delivery.lua")
