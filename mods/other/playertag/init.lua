local players = {}
local ATTACH_POSITION = minetest.rgba and {x=0, y=20, z=0} or {x=0, y=10, z=0}

local TYPE_BUILTIN = 0
local TYPE_ENTITY = 1

playertag = {
	TYPE_BUILTIN = TYPE_BUILTIN,
	TYPE_ENTITY  = TYPE_ENTITY,
	no_entity_attach = {}
}

local codepoint
if core.global_exists("algorithms") and algorithms.codepoint then
	codepoint = algorithms.codepoint
end
local function add_entity_tag(player, old_observers, readded)
	local player_name = player:get_player_name()
	-- Hide fixed nametag
	player:set_nametag_attributes({
		color = {a = 0, r = 0, g = 0, b = 0}
	})

	local ent = minetest.add_entity(player:get_pos(), "playertag:tag")
	if not ent then return end
	local ent2 = false
	local ent3 = false

	if ent.set_observers then
		ent2 = minetest.add_entity(player:get_pos(), "playertag:tag")
		ent2:set_observers(old_observers.nametag_entity or {})
		ent2:set_properties({
			nametag = player_name,
			nametag_color = "#EEFFFFDD",
			nametag_bgcolor = "#0000002D"
		})

		ent3 = minetest.add_entity(player:get_pos(), "playertag:tag")
		ent3:set_observers(old_observers.symbol_entity or {})
		ent3:set_properties({
			collisionbox = { 0, 0, 0, 0, 0, 0 },
			nametag = "V",
			nametag_color = "#EEFFFFDD",
			nametag_bgcolor = "#0000002D"
		})
	end

	-- Build name from font texture
	local texture = "npcf_tag_bg.png"
	local x = math.floor(134 - ((utf8_simple.len(player_name) * 11) / 2))
	local i = 0
	for idx, char, bidx in utf8_simple.chars(player_name) do
		local n = "_"
		if #char > 1 and codepoint then
			local code = codepoint(char)
			n = "W_U-"..string.format("%04X", code)..".png"
		elseif char:byte() > 96 and char:byte() < 123 or char:byte() > 47 and char:byte() < 58 or char == "-" then
			n = char
		elseif char:byte() > 64 and char:byte() < 91 then
			n = "U" .. char
		end
		texture = texture.."^[combine:84x14:"..(x+i+1)..",1=(W_".. n ..".png\\^[multiply\\:#000):"..
				(x+i)..",0=W_".. n ..".png"
		i = i + 11
	end
	ent:set_properties({ textures={texture} })

	-- Attach to player
	ent:set_attach(player, "", ATTACH_POSITION, {x=0, y=0, z=0})

	if ent2 and ent3 then
		ent2:set_attach(player, "", ATTACH_POSITION, {x=0, y=0, z=0})
		ent3:set_attach(player, "", ATTACH_POSITION, {x=0, y=0, z=0})
	end

	-- Store
	players[player_name].entity = ent:get_luaentity()
	players[player_name].nametag_entity = ent2 and ent2:get_luaentity()
	players[player_name].symbol_entity = ent3 and ent3:get_luaentity()

	if readded then return end
	players[player_name].timer = minetest.after(5, function()
		if minetest.get_player_by_name(player_name) ~= nil then -- check if the player is still online
			if not ent:get_luaentity() or (ent.set_observers and not (ent2:get_luaentity() or ent3:get_luaentity())) then
				minetest.log("warning", "playertag: respawning entity for " .. player_name)
				add_entity_tag(player, old_observers, true)
			end
		end
	end)
end

function playertag.remove_entity_tag(player)
	local tag = players[player:get_player_name()]
	if tag and tag.entity then
		tag.entity.object:remove()

		if tag.nametag_entity then
			tag.nametag_entity.object:remove()
		end

		if tag.symbol_entity then
			tag.symbol_entity.object:remove()
		end

		if tag.timer then
			tag.timer:cancel()
		end
	end
end

local function update(player, settings)
	local pname = player:get_player_name()
	local old_observers = {}

	if player.get_observers and players[pname] then
		local nametag_entity = players[pname].nametag_entity
		if nametag_entity and nametag_entity.object:get_pos() then
			old_observers.nametag_entity = nametag_entity.object:get_observers()
		end

		local symbol_entity = players[pname].symbol_entity
		if symbol_entity and symbol_entity.object:get_pos() then
			old_observers.symbol_entity = symbol_entity.object:get_observers()
		end
	end

	if settings.nametag_entity_observers then
		old_observers.nametag_entity = table.copy(settings.nametag_entity_observers)
		settings.nametag_entity_observers = nil
	end

	if settings.symbol_entity_observers then
		old_observers.symbol_entity = table.copy(settings.symbol_entity_observers)
		settings.symbol_entity_observers = nil
	end

	playertag.remove_entity_tag(player)
	players[pname] = settings

	if settings.type == TYPE_BUILTIN then
		player:set_nametag_attributes({
			color = settings.color or {a=255, r=255, g=255, b=255},
			bgcolor = {a=0, r=0, g=0, b=0},
		})
	elseif settings.type == TYPE_ENTITY then
		add_entity_tag(player, old_observers)
	end
end

function playertag.set(player, type, color, extra)
	if playertag.no_entity_attach[player:get_player_name()] then
		return
	end

	local oldset = players[player:get_player_name()]
	if not oldset then return end

	-- update it anyway
	extra = extra or {}
	extra.type = type
	extra.color = color

	update(player, extra)

	return players[player:get_player_name()]
end

function playertag.get(player)
	return players[player:get_player_name()]
end

function playertag.get_all()
	return players
end

minetest.register_entity("playertag:tag", {
	initial_properties = {
		visual = "sprite",
		visual_size = {x=2.16, y=0.18, z=2.16}, --{x=1.44, y=0.12, z=1.44},
		textures = {"blank.png"},
		collisionbox = { 0, -0.2, 0, 0, -0.2, 0 },
		physical = false,
		makes_footstep_sound = false,
		backface_culling = false,
		static_save = false,
		pointable = false,
	},
	on_punch = function(self, puncher, time_from_last_punch, tool_capabilities, dir, damage)
		if minetest.is_player(puncher) then
			puncher:set_hp(puncher:get_hp() - damage,  {type="punch"}) --cause damage to yourself.
			minetest.log("warning", puncher:get_player_name() .. " is trying to damage non-pointable entity \"playertag:tag\".")
		end
		return true
	end
})

minetest.register_on_joinplayer(function(player)
	local name = player:get_player_name()
	if playertag.no_entity_attach[name] then
		return
	end
	players[name] = {type = TYPE_BUILTIN, color = {a=255, r=255, g=255, b=255}}
end)

minetest.register_on_leaveplayer(function(player)
	playertag.remove_entity_tag(player)
	players[player:get_player_name()] = nil
end)
