function ctf_clans.generate_element_layout(elements, config)
	local form = ""
	local pos_x = config.pos_start[1]
	local pos_y = config.pos_start[2]

	local default_size_x = config.size[1]
	local default_size_y = config.size[2]

	local direction = config.direction or "vertical"
	local reverse = config.reverse or false

	-- Spacing handling
	local spacing_x, spacing_y
	if config.spacing then
		if type(config.spacing) == "table" then
			spacing_x = config.spacing[1]
			spacing_y = config.spacing[2]
		else
			spacing_x = config.spacing
			spacing_y = config.spacing
		end
	else
		spacing_x = 0
		spacing_y = 0
	end

	for _, element in ipairs(elements) do
		local size_x = default_size_x
		local size_y = default_size_y

		local to_format = ""
		if type(element) == "table" then
			if element.size and #element.size == 2 then
				size_x = element.size[1]
				size_y = element.size[2]
			end
			to_format = element.element
		else
			to_format = element
		end

		form = form .. string.format(to_format, pos_x, pos_y, size_x, size_y)

		if direction == "vertical" then
			local offset = size_y + spacing_y
			pos_y = pos_y + (reverse and -offset or offset)
		else
			local offset = size_x + spacing_x
			pos_x = pos_x + (reverse and -offset or offset)
		end
	end

	return form, {pos_x, pos_y}
end