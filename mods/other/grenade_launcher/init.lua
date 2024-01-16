local WEAR_MAX = 65535
minetest.register_tool("grenade_launcher:launcher", {
	description = "Grenade Launcher",
	wield_scale = {x=2.0,y=2.0,z=2.5},
	inventory_image = "grenade_launcher.png",
	range = 4,
	on_use = function(itemstack, user)
		if itemstack:get_wear() > 0 then
			return
		end
		local name = user:get_player_name()
		local pos = user:get_pos()
		local dir = user:get_look_dir()
		if pos and dir then
			pos.y = pos.y + 1.5
			local ahead = vector.add(pos, vector.multiply(dir, 1))
			local obj = minetest.add_entity(ahead, "grenade_launcher:grenade")
			if obj then
				local ent = obj:get_luaentity()
				ent.puncher_name = name
				local vel = user:get_velocity()
				local speed = math.sqrt(vel.x^2 + vel.y^2 + vel.z^2)
				obj:add_velocity(vector.multiply(dir, speed + 18))
			end
		end
		minetest.sound_play('grenade_launcher_plop',{to_player = name, gain = 0.5})
		itemstack:set_wear(WEAR_MAX - 6000)
		ctf_modebase.update_wear.start_update(user:get_player_name(), "grenade_launcher:launcher", WEAR_MAX/4, true)
		return itemstack
	end
})

local function can_explode(pos, pname, radius)
	if minetest.is_protected(pos, "") then
		minetest.chat_send_player(pname, "You can't explode grenade on spawn!")
		return false
	end

	local pteam = ctf_teams.get(pname)

	if pteam then
		for flagteam, team in pairs(ctf_map.current_map.teams) do
			if not ctf_modebase.flag_captured[flagteam] and team.flag_pos then
				local distance_from_flag = vector.distance(pos, team.flag_pos)
				if distance_from_flag <= 4 + radius then
					minetest.chat_send_player(pname, "You can't explode grenade so close to a flag!")
					return false
				end
			end
		end
	end
	return true
end

local radius = 3
minetest.register_entity("grenade_launcher:grenade", {
	initial_properties = {
		visual = "sprite",
		visual_size = {x = 1, y = 1},
		textures = {"grenade_launcher_grenade.png^[multiply:red:200"},
		physical = true,
		makes_footstep_sound = false,
		backface_culling = false,
		static_save = false,
		pointable = false,
		collide_with_objects = true,
		collisionbox = {-0.2, -0.2, -0.2, 0.2, 0.2, 0.2}
	},
	timer = 0,
	on_activate = function(self)
		minetest.add_particlespawner({
			attached = self.object,
			amount = 10,
			time = 1,
			minpos = {x = 0, y = -0.5, z = 0}, -- Offset to middle of player
			maxpos = {x = 0, y = 0.5, z = 0},
			minvel = {x = 0, y = 0, z = 0},
			maxvel = self.object:get_velocity(),
			minacc = {x = 0, y = 5, z = 0},
			maxacc = {x = 0, y = 7, z = 0},
			minexptime = 1,
			maxexptime = 2.8,
			minsize = 2,
			maxsize = 3,
			collisiondetection = false,
			collision_removal = false,
			vertical = false,
			texture = "grenades_smoke.png^[colorize:black:150",
		})
	end,
	on_step = function(self, dtime, moveresult)
		self.timer = self.timer + dtime
		if self.timer >= 60 then
			self.object:remove()
			return
		end

		local pos = self.object:get_pos()
		if not pos then return end

		if moveresult.collides then
			if can_explode(pos, self.puncher_name, radius) then
				tnt.boom(pos, {
					puncher_name = self.puncher_name,
					radius = radius,
				})
			end
			self.object:remove()
			return
		end

		local vel = self.object:get_velocity()
		if vel then
			local gravity = 9
			vel.y = vel.y - gravity * dtime
			self.object:set_velocity(vel)
		end
	end
})