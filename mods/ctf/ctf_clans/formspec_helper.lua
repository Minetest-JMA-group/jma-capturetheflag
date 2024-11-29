function ctf_clans.generate_element_layout(elements, config)
    local form = ""

    local pos_x = config.pos_start[1]
    local pos_y = config.pos_start[2]

    local default_size_x = config.size[1]
    local default_size_y = config.size[2]

    local direction = config.direction or "vertical"

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
    elseif config.spacing then
        spacing_x = config.spacing
        spacing_y = config.spacing
    else
        spacing_x = 0
        spacing_y = 0
    end

    for _, element in ipairs(elements) do
        local size_x = default_size_x
        local size_y = default_size_y

        local to_format = ""
        if type(element) == "table" then
            if element.size then
                size_x = element.size[1]
                size_y = element.size[2]
            end
            to_format = element.element
        else
            to_format = element
        end

        form = form .. string.format(to_format, pos_x, pos_y, size_x, size_y)

        if direction == "vertical" then
            pos_y = pos_y + size_y + spacing_y
        else
            pos_x = pos_x + size_x + spacing_x
        end
    end

	local last_pos = {pos_x, pos_y}
    return form, last_pos
end