-- SPDX-License-Identifier: GPL-3.0-or-later
-- Copyright (c) 2024 Ivan Shkatov (Maintainer_) ivanskatov672@gmail.com

local BREAK_REWARD_PER_HP = 0.1
local HEAL_DIG_REWARD_BASE = 20

core.register_node("ctf_healing:heal_block", {
	description = "Healing Block\n"
		.. "A block that heals players within a 3-block radius.\n"
		.. "Place it on your team's territory to keep your allies healthy nearby.\n"
		.. core.colorize(
			"yellow",
			"Warning: breaking this block will result in its loss, so defend it wisely!"
		),
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = { -0.5, -0.5, -0.5, 0.5, 0, 0.5 },
	},
	walkable = true,
	tiles = {
		{
			name = "ctf_healing_heal_block_top.png",
			align_style = "repeat",
			scale = 1,
			position = { x = 0, y = 0, z = 0.5 },
		}, -- top
		{ name = "default_aspen_wood.png^[multiply:#ffc2a7:80" },
	},
	groups = { choppy = 1, oddly_breakable_by_hand = 1 },
	sounds = default.node_sound_wood_defaults(),
	drop = "",

	on_place = function(itemstack, placer, pointed_thing)
		local pteam = ctf_teams.get(placer)
		if pteam then
			if
				not ctf_core.pos_inside(
					pointed_thing.under,
					ctf_teams.get_team_territory(pteam)
				)
			then
				hud_events.new(placer, {
					quick = true,
					text = "Healing block can only be placed on your team's area.",
					color = "warning",
				})
				return
			end
		end
		core.item_place(itemstack, placer, pointed_thing)
		return itemstack
	end,

	after_place_node = function(pos, placer)
		core.get_node_timer(pos):start(1)
		local pteam = ctf_teams.get(placer)
		if pteam then
			core.get_meta(pos):set_string("team", pteam)
		end
	end,

	on_timer = function(pos)
		local meta = core.get_meta(pos)
		local healed_points = meta:get_int("healed_points")
		for _, player in ipairs(core.get_objects_inside_radius(pos, 3)) do
			if player:is_player() then
				local pteam = ctf_teams.get(player:get_player_name())
				if pteam and pteam == meta:get_string("team") then
					local hp = player:get_hp()
					if hp < player:get_properties().hp_max then
						player:set_hp(hp + 2)
						healed_points = healed_points + 2
					end
				end
			end
		end
		meta:set_int("healed_points", healed_points)
		return true
	end,

	after_dig_node = function(pos, oldnode, oldmetadata, digger)
		local block_team = oldmetadata.fields.team
		local player_team = ctf_teams.get(digger)
		-- Only award points if player breaks enemy team's heal block
		if block_team and player_team and block_team ~= player_team then
			local cur_mode = ctf_modebase:get_current_mode()
			if not cur_mode then
				return
			end
			local meta = core.get_meta(pos)
			local healed_points = meta:get_int("healed_points")
			local break_reward = math.max(
				HEAL_DIG_REWARD_BASE,
				math.ceil(healed_points * BREAK_REWARD_PER_HP)
			)
			cur_mode.recent_rankings.add(
				digger:get_player_name(),
				{ score = break_reward },
				true
			)

			hud_events.new(digger, {
				quick = true,
				text = "You destroyed enemy's healing block! (+"
					.. break_reward
					.. " points)",
				color = "success",
			})
		end
	end,
})
