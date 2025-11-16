local hud = mhud.init()

vanish = {}
vanish.vanished = {}
vanish.old_properties = {}
vanish.old_nametag = {}
vanish.old_armor_groups = {}

function vanish.on(player, options)
	local name = player:get_player_name()
	local pos = player:get_pos()
	if not minetest.get_player_by_name(name) or not pos then
		return
	end
	vanish.vanished[name] = true

	local properties = player:get_properties()
	vanish.old_properties[name] = {
		visual = properties.visual,
		selectionbox = properties.selectionbox,
		show_on_minimap = properties.show_on_minimap,
		pointable = properties.pointable,
		visual_size = properties.visual_size,
		hp_max = properties.hp_max
	}
	vanish.old_nametag[name] = player:get_nametag_attributes()
	vanish.old_armor_groups[name] = player:get_armor_groups()

	player:override_day_night_ratio(1)
	player:set_pos(vector.add(pos, {x=0, y=1, z=0}))
	player:set_properties({
		visual = "node",
		-- collisionbox = {-0.01, 0, -0.01, 0.01, 0, 0.01},
		selectionbox = {-0.001, 0, -0.001, 0.001, 0, 0.001},
		show_on_minimap = false,
		pointable = options.pointable,
		visual_size = {x=0, y=0},
		node = {name = "ignore", param1=0, param2=0},
		is_visible = options.is_visible,
		hp_max = 5000,
	})
	player:set_hp(5000)
	player:set_nametag_attributes{
		text = "\0",
		color = {a = 0, r = 0, g = 0, b = 0}
	}

	local armor_groups = table.copy(vanish.old_armor_groups[name])
	armor_groups.immortal = 1
	player:set_armor_groups(armor_groups)

	-- player:set_eye_offset({x=0, y=-4, z=0},{x=0, y=-4, z=0})

	hpbar.no_entity_attach[name] = true
	playertag.no_entity_attach[name] = true
	wield3d.no_entity_attach[name] = true
	server_cosmetics.no_entity_attach[name] = true
	playertag.remove_entity_tag(player)
	wield3d.remove_wielditem(player)

	minetest.after(1, function()
		if not minetest.get_player_by_name(name) then
			return
		end

		local attached_list = player:get_children()
		for _, obj in ipairs(attached_list) do
			obj:remove()
		end

		minetest.chat_send_player(name, minetest.colorize("yellow", "Your attached objects have been removed."))
	end)

	minetest.chat_send_player(name, minetest.colorize("red", "Note: You are currently in Vanish mode."))
	hud:add(player, "vanish:notify", {
		type = "text",
		position = {x = 0.5, y = 0.5},
		offset = {x = 0, y = 0},
		text = "You are vanished",
		color = 0xFF0000,
		style = 3,
	})
end

function vanish.off(player)
	local name = player:get_player_name()
	if not vanish.vanished[name] or not minetest.get_player_by_name(name) then
		return
	end

	player:set_properties(vanish.old_properties[name])
	player:override_day_night_ratio()
	player:set_nametag_attributes(vanish.old_nametag[name])
	player:set_hp(vanish.old_properties[name].hp_max)

	local old_armor_groups = vanish.old_armor_groups[name]
	if old_armor_groups then
		player:set_armor_groups(old_armor_groups)
	else
		player:set_armor_groups({fleshy = 100})
	end

	hpbar.no_entity_attach[name] = nil
	playertag.no_entity_attach[name] = nil
	wield3d.no_entity_attach[name] = nil
	server_cosmetics.no_entity_attach[name] = nil

	player_api.set_model(player, "character.b3d")
	playertag.set(player, playertag.TYPE_ENTITY)
	wield3d.add_wielditem(player)
	server_cosmetics.update_entity_cosmetics(player, ctf_cosmetics.get_extra_clothing(player))

	ctf_modebase.player.update(player)

	hud:remove_all()
	vanish.vanished[name] = nil
	vanish.old_properties[name] = nil
	vanish.old_nametag[name] = nil
	vanish.old_armor_groups[name] = nil
end

minetest.register_privilege("vanish", "Allows to make players invisible")

minetest.register_on_leaveplayer(function(player)
	local name = player:get_player_name()
	vanish.vanished[name] = nil
	vanish.old_properties[name] = nil
	vanish.old_nametag[name] = nil
	vanish.old_armor_groups[name] = nil
end)

minetest.register_chatcommand("vanish", {
	description = "Toggle invisibility of player with optional parameters",
	privs = {vanish=true},
	params = "<name|!> [key=value] ...",
	func = function(name, param)
		-- Split input into words
		local args = param:split(" ")
		local target_name = args[1] ~= "" and args[1] or name -- Default to caller if no name is provided

		-- If target_name is "!", apply to the caller
		if target_name == "!" then
			target_name = name
		end

		local player = minetest.get_player_by_name(target_name)
		if not player then
			return false, "Player " .. target_name .. " is not online."
		end

		if vanish.vanished[target_name] then
			return false, "Player " .. target_name .. " is already vanished. Use /unvanish to make them visible."
		end

		-- Initialize options with defaults
		local options = {
			pointable = true,
			is_visible = false,
		}

		-- Parse key=value pairs
		for i = 2, #args do
			local key, value = args[i]:match("([^=]+)=(.+)")
			if key and value then
				if key == "pointable" then
					options.pointable = value:lower() == "true"
				elseif key == "visible" then
					options.is_visible = value:lower() == "true"
				else
					return false, "Unknown parameter: " .. key
				end
			end
		end

		vanish.on(player, options)

		local msg = "-!- " .. target_name .. " vanished with options:"
		for k, v in pairs(options) do
			msg = msg .. "\n- " .. k .. ": " .. tostring(v)
		end
		return true, msg
	end
})

minetest.register_chatcommand("unvanish", {
	description = "Toggle invisibility of player",
	privs = {vanish=true},
	params = "<name>",
	func = function(name, param)
		local target_name = param ~= "" and param or name -- Default to caller if no name is provided
		local player = minetest.get_player_by_name(target_name)
		if not player then
			return false, "Player " .. target_name .. " is not online."
		end

		if not vanish.vanished[target_name] then
			return false, "Player " .. target_name .. " is not vanished."
		end

		vanish.off(player)
		return true, target_name .. " is now visible."
	end
})

minetest.register_chatcommand("vanished", {
	description = "Show list of vanished players",
	privs = {vanish=true},
	func = function(name, param)
		local out = {}
		for nick in pairs(vanish.vanished) do
			table.insert(out, nick)
		end
		table.sort(out)
		return true, "Vanished: "..table.concat(out, ", ")
	end
})
