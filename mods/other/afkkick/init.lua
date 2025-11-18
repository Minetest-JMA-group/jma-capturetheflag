--[[
Afk Kick mod for Minetest by GunshipPenguin

To the extent possible under law, the author(s)
have dedicated all copyright and related and neighboring rights
to this software to the public domain worldwide. This software is
distributed without any warranty.
]]

local MAX_INACTIVE_TIME = 480
local CHECK_INTERVAL = 5
local WARN_TIME = 400

local players = {}
local checkTimer = 0

local S = core.get_translator(core.get_current_modname())

core.register_privilege("canafk", {
    description = S("Allow to AFK without being kicked"),
})

core.register_on_joinplayer(function(player)
	local playerName = player:get_player_name()
	players[playerName] = {
		lastAction = core.get_gametime()
	}
end)

core.register_on_leaveplayer(function(player)
	local playerName = player:get_player_name()
	players[playerName] = nil
end)

core.register_on_chat_message(function(playerName, message)
	-- Verify that there is a player, and that the player is online
	if not playerName or not core.get_player_by_name(playerName) then
		return
	end

	players[playerName]["lastAction"] = core.get_gametime()
end)

core.register_globalstep(function(dtime)
	local currGameTime = core.get_gametime()

	-- Check for inactivity once every CHECK_INTERVAL seconds
	checkTimer = checkTimer + dtime

	local checkNow = checkTimer >= CHECK_INTERVAL
	if checkNow then
		checkTimer = checkTimer - CHECK_INTERVAL
	end

	-- Loop through each player in players
	for playerName, _ in pairs(players) do
		local player = core.get_player_by_name(playerName)
		if player then
			-- Check if this player is doing an action
			local control = player:get_player_control()
			if
				control.up
				or control.down
				or control.left
				or control.right
				or control.jump
				or control.sneak
				or control.dig
				or control.place
			then
				players[playerName]["lastAction"] = currGameTime
			end

			if checkNow and not core.check_player_privs(player, {canafk = true}) then
				-- Kick player if he/she has been inactive for longer than MAX_INACTIVE_TIME seconds
				if players[playerName]["lastAction"] + MAX_INACTIVE_TIME < currGameTime then
					core.kick_player(playerName, "Kicked for inactivity")
				end

				-- Warn player if he/she has less than WARN_TIME seconds to move or be kicked
				if players[playerName]["lastAction"] + MAX_INACTIVE_TIME - WARN_TIME < currGameTime then
					local time_left = players[playerName]["lastAction"] + MAX_INACTIVE_TIME - currGameTime + 1
					hud_events.new(playerName, {
						text = S("[Warning], you have @1 seconds to move "
									.. "or be kicked for inactivity", time_left),
						color = "warning",
						channel = 3
					})
				end
			end
		end
	end
end)
