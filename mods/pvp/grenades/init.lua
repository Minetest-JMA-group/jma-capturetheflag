grenades = {
	grenade_deaccel = 8
}

local cooldown = ctf_core.init_cooldowns()
local max_vel = 30

function grenades.throw_grenade(name, startspeed, player)
	local player_vel = player:get_velocity()
	if math.abs(player_vel.x) > max_vel or math.abs(player_vel.y) > max_vel or math.abs(player_vel.z) > max_vel then
		minetest.log("warning", "grenades: Player " .. player:get_player_name() .. " exceeded the maximum allowed velocity: " .. vector.to_string(player_vel))
		return
	end

	local dir = player:get_look_dir()
	local pos = vector.offset(player:get_pos(), 0, player:get_properties().eye_height, 0)

	local obj = minetest.add_entity(pos, name)
	if not obj then
		return
	end

	obj:set_velocity(vector.add(vector.multiply(dir, startspeed), player_vel))
	obj:set_acceleration({x = 0, y = -9.8, z = 0})

	local data = obj:get_luaentity()
	data.thrower_name = player:get_player_name()

	return data
end

function grenades.register_grenade(name, def)
	if not def.clock then
		def.clock = 4
	end

	local grenade_entity = {
		initial_properties = {
			physical = true,
			collide_with_objects = def.collide_with_objects or false,
			visual = "sprite",
			visual_size = {x = 0.5, y = 0.5, z = 0.5},
			textures = {def.image},
			collisionbox = {-0.05, -0.05, -0.05, 0.05, 0.05, 0.05},
			pointable = false,
			static_save = false,
		},
		sliding = 1,
		particle = 0,
		timer = 0,
		on_step = function(self, dtime, moveresult)
			local obj = self.object
			local vel = obj:get_velocity()
			local pos = obj:get_pos()
			local norm_vel -- Normalized velocity

			self.timer = self.timer + dtime

			if not self.last_vel then
				self.last_vel = vel
			end

			-- Check for a collision on the x/y/z axis

			if moveresult.collides and moveresult.collisions then
				if def.on_collide then
					local c_result = def:on_collide(obj, self.thrower_name, moveresult)

					if c_result == true then
						if self.thrower_name then
							minetest.log("action", "[Grenades] A grenade thrown by " .. self.thrower_name ..
									" explodes at " .. minetest.pos_to_string(vector.round(pos)))
							def:on_explode(obj, pos, self.thrower_name)
						end
						obj:remove()
					elseif c_result == false then
						vel = vector.new()
						self.last_vel = vector.new()
						obj:set_velocity(vector.new())
						obj:set_acceleration(vector.new(0, 0, 0))
					end
				else
					if moveresult.collisions[1] and moveresult.collisions[1].axis then
						local axis = moveresult.collisions[1].axis

						vel[axis] = self.last_vel[axis] * -0.3
					end
				end

				obj:set_velocity(vel)
			end

			self.last_vel = vel

			norm_vel = vector.normalize(vel)

			if not vector.equals(vel, vector.new()) then
				obj:set_acceleration({
					x = -norm_vel.x * grenades.grenade_deaccel * (moveresult.touching_ground and 2 or 1),
					y = -9.8,
					z = -norm_vel.z * grenades.grenade_deaccel * (moveresult.touching_ground and 2 or 1),
				})
			end

			if moveresult.touching_ground then -- Is the grenade sliding?
				-- If grenade is barely moving, make sure it stays that way
				if vector.distance(vector.new(), vel) <= 2 and not vector.equals(vel, vector.new()) then
					obj:set_velocity(vector.new())
					obj:set_acceleration(vector.new(0, -9.8, 0))
				end
			end

			-- Grenade Particles

			if def.particle and self.particle >= def.particle.interval then
				self.particle = 0

				minetest.add_particle({
					pos = obj:get_pos(),
					velocity = vector.divide(vel, 2),
					acceleration = vector.divide(obj:get_acceleration() or vector.new(1, 1, 1), -5),
					expirationtime = def.particle.life,
					size = def.particle.size,
					collisiondetection = false,
					collision_removal = false,
					vertical = false,
					texture = def.particle.image,
					glow = def.particle.glow
				})
			elseif def.particle and self.particle < def.particle.interval then
				self.particle = self.particle + dtime
			end

			-- Explode when clock is up

			if self.timer > def.clock or not self.thrower_name then
				if self.thrower_name then
					minetest.log("action", "[Grenades] A grenade thrown by " .. self.thrower_name ..
					" explodes at " .. minetest.pos_to_string(vector.round(pos)))
					def:on_explode(obj, pos, self.thrower_name)
				end

				obj:remove()
			end
		end
	}

	minetest.register_entity(name, grenade_entity)

	local newdef = {grenade = def}

	newdef.description = def.description
	newdef.stack_max = math.max(1, def.stack_max or 1)
	newdef.inventory_image = def.image
	newdef.touch_interaction = "short_dig_long_place" -- throw with short tap
	local on_use = function(itemstack, user, pointed_thing)
		if pointed_thing.type ~= "node" then
			grenades.throw_grenade(name, 17, user)

			if not minetest.settings:get_bool("creative_mode") and (def.stack_max or 99) > -1 then
				itemstack:take_item(1)
			end
		end

		return itemstack
	end

	if def.throw_cooldown then
		newdef.on_use = function(itemstack, user, ...)
			if cooldown:get(user) then
				return
			else
				cooldown:set(user, def.throw_cooldown)
			end

			return on_use(itemstack, user, ...)
		end
	else
		newdef.on_use = on_use
	end

	minetest.register_craftitem(name, newdef)
end

dofile(minetest.get_modpath("grenades") .. "/grenades.lua")
