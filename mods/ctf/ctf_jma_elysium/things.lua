local COOLDOWN = ctf_core.init_cooldowns()
local S = core.get_translator(core.get_current_modname())

local function make_pvp_switch(pvp_on)
	return {
		description = S(
			"Switch pvp mode (Currently PVP @1)",
			(pvp_on and S("ON") or S("OFF"))
		),
		inventory_image = "ctf_jma_elysium_pvp_" .. (pvp_on and "on" or "off") .. ".png",
		stack_max = 1,
		range = 3,
		on_use = function(itemstack, user)
			local name = user:get_player_name()
			local ctx = ctf_jma_elysium.players[name]
			if not ctx then
				core.chat_send_player(name, S("You are not in elysium."))
				return
			end

			local new_mode = ctf_jma_elysium.set_pvp_mode(user)
			if new_mode == nil then
				return
			end

			itemstack:set_name("ctf_jma_elysium:pvp_" .. (new_mode and "on" or "off"))
			cmsg.push_message_player(
				user,
				S("PVP Mode @1", (new_mode and S("ON") or S("OFF")))
			)
			return itemstack
		end,
		on_drop = function() end,
	}
end

core.register_craftitem("ctf_jma_elysium:pvp_on", make_pvp_switch(true))
core.register_craftitem("ctf_jma_elysium:pvp_off", make_pvp_switch(false))

do
	local apple_def = table.copy(core.registered_nodes["default:apple"])
	apple_def.description = S("Infinite Apple (Copy of default apple)")
	apple_def.tiles = { "ctf_jma_elysium_inf_apple.png" }
	apple_def.inventory_image = "ctf_jma_elysium_inf_apple.png"
	apple_def.stack_max = 1
	apple_def.on_use = function(itemstack, user, ...)
		if not COOLDOWN:get(user) then
			COOLDOWN:set(user, 0.2)

			local hp = user:get_hp()
			if hp > 0 then
				user:set_hp(hp + 3)
			end
		end
	end
	core.register_node("ctf_jma_elysium:inf_apple", apple_def)
end

core.register_node("ctf_jma_elysium:box_respawn", {
	description = S("PvP Box Respawn Point"),
	tiles = {
		{
			name = "ctf_jma_elysium_box_respawn.png",
			align_style = "world",
			scale = 1,
			position = { x = 0, y = 0, z = 0.5 },
		}, -- top
		{ name = "ctf_jma_elysium_box_respawn_side.png" },
	},
	groups = { cracky = 3, oddly_breakable_by_hand = 1, not_in_creative_inventory = 1 },
	sounds = default.node_sound_stone_defaults(),
	on_place = function(itemstack, placer, pointed_thing)
		if placer and placer:is_player() then
			local name = placer:get_player_name()
			local pos = pointed_thing and pointed_thing.above

			if not pos then
				return itemstack
			end

			local box = ctf_jma_elysium.get_box_at(pos)

			if not box then
				core.chat_send_player(
					name,
					S(
						"[PvP Box] Respawn markers can only be placed inside a PvP Box."
					)
				)
				return itemstack
			end

			if
				box.owner ~= name
				and not core.check_player_privs(name, { ctf_admin = true })
			then
				core.chat_send_player(
					name,
					S(
						"[PvP Box] Only the owner of the PvP Box can place respawn markers."
					)
				)
				return itemstack
			end
		end

		return core.item_place(itemstack, placer, pointed_thing)
	end,
	can_dig = function(pos, player)
		if not player then
			return false
		end

		local name = player:get_player_name()
		local box = ctf_jma_elysium.get_box_at(pos)
		if
			box
			and (
				box.owner == name
				or core.check_player_privs(name, { ctf_admin = true })
			)
		then
			return true
		end

		core.chat_send_player(
			name,
			S(
				"[PvP Box] Only the owner of the PvP Box can remove respawn markers."
			)
		)
		return false
	end,
	after_place_node = function(pos, placer)
		local box = ctf_jma_elysium.get_box_at(pos)
		if not box then
			return
		end

		ctf_jma_elysium.add_box_respawn_node(box, pos)

		if placer and placer:is_player() then
			core.chat_send_player(
				placer:get_player_name(),
				S(
					"[PvP Box] Respawn point set. Players will respawn above this node."
				)
			)
		end
	end,
	on_destruct = function(pos)
		local box = ctf_jma_elysium.get_box_at(pos)
		if box then
			ctf_jma_elysium.remove_box_respawn_node(box, pos)
		end
	end,
})

local deny_items = {
	["ctf_jma_elysium:pvp_on"] = true,
	["ctf_jma_elysium:pvp_off"] = true,
}

core.register_allow_player_inventory_action(function(player, action, inventory, info)
	if ctf_jma_elysium.get_player(player:get_player_name()) then
		if action == "take" and info.stack and deny_items[info.stack:get_name()] then
			return 0
		end
	end
end)
