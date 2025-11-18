local hud = mhud.init()
local hitters = {}
local healers = {}

ctf_combat_mode = {}

local function update(player)
	local combat = hitters[player]

	if combat.time <= 0 then
		hud:remove(player, "combat_indicator")
		hitters[player] = nil
		return
	end

	local hud_message = "You are in combat [%ds left] \n%s"
	hud_message = hud_message:format(combat.time, combat.suffocation_message)

	if hud:exists(player, "combat_indicator") then
		hud:change(player, "combat_indicator", {
			text = hud_message,
		})
	else
		hud:add(player, "combat_indicator", {
			type = "text",
			position = { x = 1, y = 0.2 },
			alignment = { x = "left", y = "down" },
			offset = { x = -6, y = 0 },
			text = hud_message,
			color = 0xF00000,
		})
	end

	local pos = vector.offset(core.get_player_by_name(player):get_pos(), 0, 0.5, 0)
	local node = core.registered_nodes[core.get_node(pos).name]

	if node.groups.real_suffocation then -- From real_suffocation mod
		combat.time = combat.time + 0.5
		combat.suffocation_message =
			"You are inside blocks. Move out to stop your combat timer from increasing."
	else
		combat.time = combat.time - 1
		combat.suffocation_message = ""
	end

	combat.timer = core.after(1, update, player)
end

function ctf_combat_mode.add_hitter(player, hitter, weapon_image, time)
	player = PlayerName(player)
	hitter = PlayerName(hitter)

	if not hitters[player] then
		hitters[player] = { hitters = {}, time = time }
	end

	local combat = hitters[player]
	combat.hitters[hitter] = true
	combat.time = time
	combat.last_hitter = hitter
	combat.weapon_image = weapon_image
	combat.suffocation_message = ""

	if not combat.timer then
		update(player)
	end
end

function ctf_combat_mode.add_healer(player, healer, time)
	player = PlayerName(player)
	healer = PlayerName(healer)

	if not healers[player] then
		healers[player] = {
			healers = {},
			timer = core.after(time, function()
				healers[player] = nil
			end),
		}
	end

	healers[player].healers[healer] = true
end

function ctf_combat_mode.get_last_hitter(player)
	player = PlayerName(player)

	if hitters[player] then
		return hitters[player].last_hitter, hitters[player].weapon_image
	end
end

function ctf_combat_mode.get_other_hitters(player, last_hitter)
	player = PlayerName(player)

	local ret = {}

	if hitters[player] then
		for pname in pairs(hitters[player].hitters) do
			if pname ~= last_hitter then
				table.insert(ret, pname)
			end
		end
	end

	return ret
end

function ctf_combat_mode.get_healers(player)
	player = PlayerName(player)

	local ret = {}

	if healers[player] then
		for pname in pairs(healers[player].healers) do
			table.insert(ret, pname)
		end
	end

	return ret
end

local ALL_HEALERS_DEFAULT_MAX_DEPTH = 3
--- Get all healers of a player recursively. That is, if ANAND healed
--- Kat and Kat healed savilli, the Knight, both ANAND and Kat are the
--- healers. Note that the depth matters. And ANAND has d=1.
---
--- Also each healer has a "part" in this which is later used by
--- ctf_modebase to calculate score. "part" of a healer is
--- `2^(max_depth - depth + 1)` where `^` is "to the power of".
---
--- The second value this function returns is the sum of all parts.
--- @param player PlayerName | ObjectRef
--- @param max_depth? integer
--- @return {[PlayerName]: number}, number
function ctf_combat_mode.get_all_healers(player, max_depth)
	max_depth = max_depth or ALL_HEALERS_DEFAULT_MAX_DEPTH
	--- @type { [PlayerName]: number }
	local healers2 = {}
	--- @type number
	local parts = 0
	local BASE = 3

	--- @param player2 PlayerName
	--- @param depth integer
	local function get_recursively(player2, depth)
		local healers_this = ctf_combat_mode.get_healers(player2)
		for _, healer in ipairs(healers_this) do
			local healer_part = BASE ^ (max_depth - depth + 1)
			healers2[healer] = healer_part
			parts = parts + healer_part
			if depth < max_depth then
				get_recursively(healer, depth + 1)
			end
		end
	end
	get_recursively(PlayerName(player), 0)
	return healers2, parts
end

function ctf_combat_mode.is_only_hitter(player, hitter)
	player = PlayerName(player)

	if not hitters[player] then
		return false
	end

	for pname in pairs(hitters[player].hitters) do
		if pname ~= hitter then
			return false
		end
	end

	return true
end

function ctf_combat_mode.set_kill_time(player, time)
	player = PlayerName(player)

	if hitters[player] then
		hitters[player].time = time
	end
end

function ctf_combat_mode.in_combat(player)
	return hitters[PlayerName(player)] and true or false
end

function ctf_combat_mode.end_combat(player)
	player = PlayerName(player)

	if hitters[player] then
		if hud:exists(player, "combat_indicator") then
			hud:remove(player, "combat_indicator")
		end

		hitters[player].timer:cancel()
		hitters[player] = nil
	end

	if healers[player] then
		healers[player].timer:cancel()
		healers[player] = nil
	end
end

ctf_api.register_on_match_end(function()
	for _, combat in pairs(hitters) do
		combat.timer:cancel()
	end
	hitters = {}
	for _, combat in pairs(healers) do
		combat.timer:cancel()
	end
	healers = {}
	hud:remove_all()
end)
