ctf_cosmetics = {}
minetest.get_modpath("simple_skin")
function ctf_cosmetics.get_colored_skin(player, color)
	color = color or "white"
	local extras = {}

	for clothing, clothcolor in pairs(ctf_cosmetics.get_extra_clothing(player)) do
		local append = false

		if type(clothcolor) == "table" then
			append = clothcolor.append
			clothcolor = clothcolor.color
		end

		if clothing:sub(1, 1) ~= "_" then
			local texture = ctf_cosmetics.get_clothing_texture(player, clothing)

			if texture then
				table.insert(extras, append and (#extras + 1) or 1, string.format(
					"^(%s^[multiply:%s)",
					texture,
					clothcolor
				))
			end
		end
	end
	local meta = player:get_meta()
	skin = meta:get_string("simple_skins:skin")
	if skin == "" then 
		skin = "character"
	else 
		skin = meta:get_string("simple_skins:skin")
	end
	return string.format(
		skin ..  ".png".."^(%s^[multiply:%s)^(%s^[multiply:%s)%s",
		ctf_cosmetics.get_clothing_texture(player, "shirt"), color,
		ctf_cosmetics.get_clothing_texture(player, "pants"), color,
		table.concat(extras)
	)
end
function ctf_cosmetics.get_skin(player)
	local pteam = ctf_teams.get(player)

	return ctf_cosmetics.get_colored_skin(player, pteam and ctf_teams.team[pteam].color)
end