function server_cosmetics.enable_graves()
	core.register_on_dieplayer(function(player, reason)
		if reason.type == "punch" and not server_cosmetics.disable_graves then
			local team = ctf_teams.get(player)
			local letters = "server_cosmetics_grave_rip.png"

			if team then
				letters = string.format("(%s^[multiply:%s)", letters, ctf_teams.team[team].color)
			end

			core.add_particle({
				pos = player:get_pos():offset(0, 1.5, 0),
				velocity = vector.new(0, -10, 0),
				expirationtime = 30,
				size = 10,
				collisiondetection = true,
				collision_removal = false,
				object_collision = false,
				vertical = true,
				texture = "server_cosmetics_grave.png^" .. letters,
				glow = 1,
			})
		end
	end)
end
