minetest.register_entity("server_cosmetics:hat", {
	visual = "mesh",
	textures = {},
	mesh = "server_cosmetics_hat.b3d",
	physical = false,
	makes_footstep_sound = false,
	backface_culling = false,
	shaded = false,
	static_save = false,
	pointable = false,
	glow = 1,
	on_punch = function() return true end,
	on_step = function(self, dtime)
		self.timer = (self.timer or 0) + dtime
		if not self.animr or self.timer < 0.3 then return end
		self.timer = 0

		local player = self.object:get_attach()

		if not player or not player:is_player() then
			self.object:remove()
			return
		end

		local vel = player:get_velocity()
		local movement = vector.length(vel)

		if movement ~= 0 then
			if self.animr.falling and vel.y <= -12 then
				self.object:set_animation(self.animr.falling, 40)
				return
			elseif self.animr.bumpy and movement ~= vel.y then
				self.object:set_animation(self.animr.bumpy, 16)
				return
			end
		end

		self.object:set_animation(self.animr.idle, 2)
	end
})
