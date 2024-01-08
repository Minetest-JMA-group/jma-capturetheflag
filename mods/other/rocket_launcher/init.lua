local default_radius = tonumber(minetest.settings:get("rocket_launcher_radius")) or 3
local ballistic = minetest.settings:get_bool("rocket_launcher_ballistic", true)

minetest.register_craftitem("rocket_launcher:rocket", {
	wield_scale = {x=1,y=1,z=1.5},
	stack_max = 16,
	description = "Rocket",
	inventory_image = "rocket.png",
})

local WEAR_MAX = 65535
minetest.register_tool("rocket_launcher:launcher", {
	wield_scale = {x=1,y=1,z=2},
	description = "Rocket Launcher\nUses rockets",
	inventory_image = "rocket_launcher.png",
	on_use = function(itemstack, user)
		if itemstack:get_wear() > 0 then
			return
		end
		local name = user:get_player_name()
		local inv = user:get_inventory()
		if inv:contains_item("main", "rocket_launcher:rocket") then
			inv:remove_item("main", "rocket_launcher:rocket 1")
			local pos = user:get_pos()
			local dir = user:get_look_dir()
			local pitch = user:get_look_vertical()
			if pos and dir then
				pos.y = pos.y + 1.5
				local obj = minetest.add_entity(pos, "rocket_launcher:rocket")
				if obj then
					local ent = obj:get_luaentity()
					ent.radius = default_radius
					ent.puncher_name = name
					obj:set_velocity({x=dir.x * 30, y=dir.y * 30, z=dir.z * 30})
					user:add_velocity({x=dir.x * -4, y=dir.y * -4, z=dir.z * -4})
					if ballistic == true then
						obj:set_acceleration({x=0,z=0,y=-1})
					end
					obj:set_rotation({x=-pitch, y=0, z=0})
				end
			end
			minetest.sound_play('fire_extinguish_flame',{to_player = name, gain = 0.5})
			itemstack:set_wear(WEAR_MAX - 6000)
			ctf_modebase.update_wear.start_update(user:get_player_name(), "rocket_launcher:launcher", WEAR_MAX/4, true)
			return itemstack
		end
	end
})

local rocket = {
	initial_properties = {
		armor_groups = {immortal = true},
		physical = true,
		visual = "mesh",
		mesh = 'rocket.obj',
		visual_size = {x=0.7, y=0.7,},
		textures = {'rocket_mesh.png'},
		pointable = false,
		collisionbox = {-0.25,-0.25,-0.25,0.25,0.25,0.25},
		collide_with_objects = false,
		automatic_face_movement_dir = 270,
		static_save = false,
	},
	timer = 0,
}

rocket.on_step = function(self, dtime, moveresult)
	self.timer = self.timer + dtime
	local pos = self.object:get_pos()
	if not pos then return end
	minetest.after(0.1,function()
		minetest.add_particle({
			pos = pos,
			velocity = {x=math.random(-0.5,0.5),y=math.random(-0.5,0.5),z=math.random(-0.5,0.5)},
			expirationtime = 0.1,
			size = 6,
			collisiondetection = false,
			vertical = false,
			texture = "tnt_boom.png",
			glow = 15})
		minetest.add_particle({
			pos = pos,
			velocity = {x=math.random(-1,1),y=math.random(-1,1),z=math.random(-1,1)},
			expirationtime = 0.7,
			size = 6,
			collisiondetection = false,
			vertical = false,
			texture = "tnt_smoke.png",
			glow = 15})
	end)
	if self.timer >= 60 then
		self.object:remove()
	end
	if self.timer > 0.2 then
		local objs = minetest.get_objects_inside_radius({x = pos.x, y = pos.y-1, z = pos.z}, 1)
		for k, obj in pairs(objs) do
			local prop = obj and obj:get_properties()
			if prop then
				if obj:is_player() or prop.collide_with_objects == true then
					if not minetest.is_protected(pos,"") then
						tnt.boom(pos, {
							radius = self.radius,
							puncher_name = self.puncher_name
						})
					end
					self.object:remove()
				end
			end
		end
	end

	if moveresult.collides then
		if not minetest.is_protected(pos,"") then
			tnt.boom(pos, {
				radius = self.radius,
				-- ignore_indestructible = true,
				puncher_name = self.puncher_name
			})
		end
		self.object:remove()
	end
end


minetest.register_entity("rocket_launcher:rocket", rocket)
