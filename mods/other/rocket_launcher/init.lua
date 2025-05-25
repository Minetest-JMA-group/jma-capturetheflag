local default_radius = 3


core.register_craftitem("rocket_launcher:rocket", {
	wield_scale = {x=2,y=2,z=1.5},
	stack_max = 16,
	description = "Rocket",
	inventory_image = "rocket.png",
})

local WEAR_MAX = 65535
core.register_tool("rocket_launcher:launcher", {
	wield_scale = {x=2,y=2,z=2},
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
				local ahead = vector.add(pos, vector.multiply(dir, 1))
				local obj = core.add_entity(ahead, "rocket_launcher:rocket")
				if obj then
					local ent = obj:get_luaentity()
					ent.radius = default_radius
					ent.puncher_name = name
					obj:set_velocity({x=dir.x * 45, y=dir.y * 45, z=dir.z * 45})
					user:add_velocity({x=dir.x * -20, y=dir.y * -20, z=dir.z * -20})
					obj:set_acceleration({x=0,z=0,y=-1})
					obj:set_rotation({x=-pitch, y=0, z=0})
				end
			end
			core.sound_play('fire_extinguish_flame',{to_player = name, gain = 0.5})
			itemstack:set_wear(WEAR_MAX - 6000)
			ctf_modebase.update_wear.start_update(user:get_player_name(), itemstack, WEAR_MAX/4, true)
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

local function can_explode(pos, pname, radius)
	if core.is_protected(pos, "") then
		core.chat_send_player(pname, "You can't explode rocket on spawn")
		return false
	end

	local pteam = ctf_teams.get(pname)

	if pteam then
		for flagteam, team in pairs(ctf_map.current_map.teams) do
			if not ctf_modebase.flag_captured[flagteam] and team.flag_pos then
				local distance_from_flag = vector.distance(pos, team.flag_pos)
				if distance_from_flag <= 2 + radius then
					core.chat_send_player(pname, "You can't explode rocket so close to a flag!")
					return false
				end
			end
		end
	end
	return true
end

rocket.on_step = function(self, dtime, moveresult)
	self.timer = self.timer + dtime
	local pos = self.object:get_pos()
	if not pos then return end
	core.after(0.1,function()
		core.add_particle({
			pos = pos,
			velocity = {x=math.random(-1,1),y=math.random(-1,1),z=math.random(-1,1)},
			expirationtime = 1.9,
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
		local objs = core.get_objects_inside_radius({x = pos.x, y = pos.y-1, z = pos.z}, 1.3)
		for k, obj in pairs(objs) do
			local prop = obj and obj:get_properties()
			if prop then
				if obj:is_player() or prop.collide_with_objects == true then
					if can_explode(pos, self.puncher_name, self.radius) then
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
		if can_explode(pos, self.puncher_name, self.radius)  then
			tnt.boom(pos, {
				radius = self.radius,
				-- ignore_indestructible = true,
				puncher_name = self.puncher_name
			})
		end
		self.object:remove()
	end
end


core.register_entity("rocket_launcher:rocket", rocket)
