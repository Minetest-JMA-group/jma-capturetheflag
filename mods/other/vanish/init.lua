local hud = mhud.init()

vanish = {}
vanish.vanished = {}
vanish.old_armor_groups = {}

function vanish.on(player)
	local player_name = player:get_player_name()

	if not core.get_player_by_name(player_name) then
		return
	end

	vanish.vanished[player_name] = true
	vanish.old_armor_groups[player_name] = player:get_armor_groups()

	player:override_day_night_ratio(1)
	player:set_observers({})
	player:set_hp(5000)

	local armor_groups = table.copy(vanish.old_armor_groups[player_name])
	armor_groups.immortal = 1
	player:set_armor_groups(armor_groups)

	core.chat_send_player(player_name, core.colorize("red", "Note: You are currently in Vanish mode."))

	hud:add(player, "vanish:notify", {
		type = "text",
		position = {x = 0.5, y = 0.5},
		offset = {x = 0, y = 30},
		text = "You are vanished",
		color = 0xFF00FF,
		style = 3,
	})
end

function vanish.off(player)
	local player_name = player:get_player_name()

	if not vanish.vanished[player_name] or not core.get_player_by_name(player_name) then
		return
	end

	player:override_day_night_ratio()
	player:set_observers(nil)

	local old_armor_groups = vanish.old_armor_groups[player_name]
	if old_armor_groups then
		player:set_armor_groups(old_armor_groups)
	else
		player:set_armor_groups({fleshy = 100})
	end

	hud:remove_all()

	vanish.vanished[player_name] = nil
	vanish.old_armor_groups[player_name] = nil
end

core.register_privilege("vanish", "Allows to make players invisible")

core.register_on_leaveplayer(function(player)
	local player_name = player:get_player_name()
	vanish.vanished[player_name] = nil
	vanish.old_armor_groups[player_name] = nil
end)

core.register_chatcommand("vanish", {
	description = "Toggle invisibility",
	privs = {vanish = true},
	func = function(player_name)
		local player = core.get_player_by_name(player_name)

		if not player then
			return false, "Player is not online."
		end

		if vanish.vanished[player_name] then
			return false, "You are already vanished. Use /unvanish first."
		end

		vanish.on(player)
		return true, "You are now vanished."
	end
})

core.register_chatcommand("unvanish", {
	description = "Toggle visibility",
	privs = {vanish = true},
	func = function(player_name)
		local player = core.get_player_by_name(player_name)

		if not player then
			return false, "Player is not online."
		end

		if not vanish.vanished[player_name] then
			return false, "You are not vanished."
		end

		vanish.off(player)
		return true, "You are now visible."
	end
})

core.register_chatcommand("vanished", {
	description = "Show list of vanished players",
	privs = {vanish = true},
	func = function()
		local out = {}

		for player_name in pairs(vanish.vanished) do
			table.insert(out, player_name)
		end

		table.sort(out)

		return true, "Vanished: " .. table.concat(out, ", ")
	end
})
