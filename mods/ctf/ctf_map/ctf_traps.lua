local S = core.get_translator(core.get_current_modname())

core.register_node("ctf_map:unwalkable_dirt", {
	description = "Unwalkable Dirt",
	tiles = { "default_dirt.png^[colorize:#ffff00:19" },
	is_ground_content = false,
	walkable = false,
	groups = { crumbly = 3, soil = 1 },
})

core.register_node("ctf_map:unwalkable_stone", {
	description = "Unwalkable Stone",
	tiles = { "default_stone.png^[colorize:#ffff00:17" },
	is_ground_content = false,
	walkable = false,
	groups = { cracky = 3, stone = 1 },
})

core.register_node("ctf_map:unwalkable_cobble", {
	description = "Unwalkable Cobblestone",
	tiles = { "default_cobble.png^[colorize:#ffff00:15" },
	is_ground_content = false,
	walkable = false,
	groups = { cracky = 3, stone = 2 },
})

--
--- Spike Trap
--

--- @param prefix string
--- @param team Team?
--- @return fun(itemstack: ItemStack, placer: (PlayerRef|LuaEntityRef)?, pointed_thing: any): ItemStack
local function spike_on_place_wrapper(prefix, team)
	local function on_place_inner(itemstack, placer, pointed_thing)
		if placer and placer:is_player() then
			---@cast placer PlayerRef
			local pteam = ctf_teams.get(placer)
			if pteam then
				local pname = placer:get_player_name()

				if
					not ctf_core.pos_inside(
						pointed_thing.above,
						ctf_teams.get_team_territory(pteam)
					)
				then
					core.chat_send_player(
						pname,
						"You can only place spikes in your own territory!"
					)
					return itemstack
				end

				local newitemstack = ItemStack(prefix .. pteam)
				newitemstack:set_count(itemstack:get_count())

				local result = core.item_place(newitemstack, placer, pointed_thing, 34)

				if result then
					local meta = core.get_meta(pointed_thing.above)
					meta:set_string("placer", pname)
					if team then
						meta:set_string("placer_team", ctf_teams.get(pname))
					end

					itemstack:set_count(result:get_count())
				end

				return itemstack
			end
		end

		return core.item_place(itemstack, placer, pointed_thing, 34)
	end
	return on_place_inner
end

--- @alias SpikeDef {
--- title: string,
--- level: number,
--- cracky: number,
--- texture: string,
--- damage: number}
--- @type { [string]: SpikeDef }
local spikes = {
	["spike"] = {
		title = "Spike",
		level = 2,
		cracky = 1.5,
		texture = "ctf_map_spike.png",
		damage = 7,
	},
	["spike_mese"] = {
		title = "Mese Spike",
		level = 3,
		cracky = 1,
		texture = "ctf_map_spike_mese.png",
		damage = 9,
	},
	["spike_diamond"] = {
		title = "Diamond Spike",
		level = 3,
		cracky = 1,
		texture = "ctf_map_spike_diamond.png",
		damage = 10,
	},
	["spike_double_mese"] = {
		title = "Double Mese Spike",
		level = 3,
		cracky = 1,
		texture = "ctf_map_spike_double_mese.png",
		damage = 12,
	},
	["spike_double_diamond"] = {
		title = "Double Diamond Spike",
		level = 3,
		cracky = 1,
		texture = "ctf_map_spike_double_diamond.png",
		damage = 13,
	},
}

--- @param name string
--- @param def SpikeDef
--- @param team ({ overlay: string, drop: string, team: Team })?
local function register_spike(name, def, team)
	local on_place = nil
	if not team then
		on_place =
			spike_on_place_wrapper(string.format("ctf_map:%s_", name), team and team.team)
	end

	core.register_node("ctf_map:" .. name, {
		description = S(def.title) .. "\n" .. S("@1 DPS", def.damage) .. "\n" .. S(
			"Damages enemies that walk on it"
		),
		drop = (team and team.drop) or nil,
		drawtype = "plantlike",
		tiles = { def.texture .. ((team and team.overlay) or "") },
		inventory_image = def.texture .. ((team and team.overlay) or ""),
		use_texture_alpha = "clip",
		paramtype = "light",
		paramtype2 = "meshoptions",
		sunlight_propagates = true,
		walkable = false,
		damage_per_second = 5,
		groups = { cracky = def.cracky, level = def.level },
		selection_box = {
			type = "fixed",
			fixed = { -0.5, -0.5, -0.5, 0.5, 0, 0.5 },
		},
		on_place = on_place,
	})
end

for name, def in pairs(spikes) do
	register_spike(name, def)
end

for team, team_def in pairs(ctf_teams.team) do
	local spikecolor = team_def.color

	for name, def in pairs(spikes) do
		register_spike(string.format("%s_%s", name, team), def, {
			overlay = string.format("^[colorize:%s:150", spikecolor),
			drop = "ctf_map:" .. name,
			team = team,
		})
	end
end

core.register_on_player_hpchange(function(player, hp_change, reason)
	if
		reason.type == "node_damage"
		and #reason.node >= 13
		and reason.node:sub(1, 13) == "ctf_map:spike"
	then
		local team = ctf_teams.get(player)

		local spike_name, spike_team = reason.node:match("ctf_map:(.*)_(.*)")

		if team and team == spike_team then
			return 0, true
		end
		if reason.node_pos then
			local meta = core.get_meta(reason.node_pos)
			local pteam = meta:get_string("placer_team")
			local pname = meta:get_string("placer")
			local damage = (spikes[spike_name] and spikes[spike_name].damage) or 1
			if pteam ~= team then
				local placer = core.get_player_by_name(pname)
				if ctf_teams.get(pname) == team then
					player:set_hp(player:get_hp() - damage)
					return -damage, false
				elseif placer then
					player:punch(placer, 1, { fleshy = damage, spike = 1 })
					return -damage, false
				end
			end
		end
	end

	return hp_change
end, true)

--
-- Damage Nodes
--

local function damage_node_dig(pos, node, digger)
	if not digger:is_player() then
		return
	end

	local digger_name = digger:get_player_name()
	local digger_team = ctf_teams.get(digger_name)

	local meta = core.get_meta(pos)
	local placer_name = meta:get_string("placer")
	meta:set_string("placer", "")

	local placer_team = ctf_teams.get(placer_name)
	if placer_team ~= digger_team and not ctf_modebase.match_started then
		return
	end

	if digger_team == placer_team then
		return
	end

	local damage_groups = { fleshy = 7 }

	if node.name == "ctf_map:damage_cobble" then
		damage_groups.damage_cobble = 1
	elseif node.name == "ctf_map:damage_glass" then
		damage_groups.damage_glass = 1
	end

	-- Apply damage
	local placerobj = core.get_player_by_name(placer_name)

	if placerobj then
		digger:punch(placerobj, 10, { damage_groups = damage_groups })
	else
		digger:set_hp(digger:get_hp() - 7)
	end

	core.remove_node(pos)
	return true
end

core.register_node("ctf_map:damage_cobble", {
	description = "Damage Cobble",
	tiles = { "ctf_map_damage_cobble.png" },
	is_ground_content = false,
	walkable = true,
	groups = { cracky = 3, stone = 2 },
	sounds = default.node_sound_stone_defaults(),
	on_ranged_shoot = function(pos, node, shooter, type)
		if type == "pistol" then
			return
		end

		if not damage_node_dig(pos, node, shooter) then
			core.dig_node(pos)
		end
	end,
	on_dig = function(pos, node, digger)
		if not damage_node_dig(pos, node, digger) then
			return core.node_dig(pos, node, digger)
		end
	end,
	after_place_node = function(pos, placer, itemstack, pointed_thing)
		if not placer or not placer:is_player() then
			return
		end
		---@cast placer PlayerRef
		local meta = core.get_meta(pos)
		meta:set_string("placer", placer:get_player_name())
	end,
})

core.register_node("ctf_map:damage_glass", {
	description = "Damage Glass",
	tiles = {
		"default_glass.png^[colorize:#B00000:180^default_glass_detail.png",
		"default_glass_detail.png",
	},
	groups = { cracky = 3 },
	sounds = default.node_sound_glass_defaults(),
	drawtype = "glasslike_framed_optional",
	use_texture_alpha = "clip",
	paramtype = "light",
	sunlight_propagates = true,
	on_ranged_shoot = function(pos, node, shooter, type)
		if not damage_node_dig(pos, node, shooter) then
			core.dig_node(pos)
		end
	end,
	on_dig = function(pos, node, digger)
		if not damage_node_dig(pos, node, digger) then
			return core.node_dig(pos, node, digger)
		end
	end,
	after_place_node = function(pos, placer, itemstack, pointed_thing)
		if not placer or not placer:is_player() then
			return
		end
		---@cast placer PlayerRef
		local meta = core.get_meta(pos)
		meta:set_string("placer", placer:get_player_name())
	end,
})

--
-- Reinforced Nodes
--

core.register_node("ctf_map:reinforced_cobble", {
	description = "Reinforced Cobblestone",
	tiles = { "ctf_map_reinforced_cobble.png" },
	is_ground_content = false,
	groups = { cracky = 1, stone = 2 },
	on_blast = function() end,
	sounds = default.node_sound_stone_defaults(),
})

core.register_node("ctf_map:reinforced_glass", {
	description = "Reinforced Glass",
	tiles = {
		"default_glass.png^[colorize:#000:140^default_glass_detail.png",
		"default_glass_detail.png",
	},
	groups = { cracky = 2 },
	on_blast = function() end,
	sounds = default.node_sound_glass_defaults(),
	drawtype = "glasslike_framed_optional",
	use_texture_alpha = "clip",
	paramtype = "light",
	sunlight_propagates = true,
})
