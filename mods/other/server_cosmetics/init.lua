server_cosmetics = {
	no_entity_attach = {},
	cosmetics = {
		default_cosmetics = {
			hair = {
				brown  = "#472E16",
				black  = "#222"   ,
				grey   = "#AAA"   ,
				blonde = "#E6CC7C",
			},
			eyes = {
				blue  = "#2859C5",
				green = "#477C47",
				brown = "#2D1400",
			},
			skin = {
				_prefix = "Modify ",
				tan      = "#cca586",
				dark_tan = "#6d4832",
				brown    = "#412d1b",
			}
		},
		headwear = {
			sunglasses = {
				_prefix = "Wear ",
				_description = "Sunglasses",
				_texture = "server_cosmetics_sunglasses.png",
				blue = {
					append = true,
					color = "#0056ff^server_cosmetics_sunglasses_shine.png",
				},
				red = {
					append = true,
					color = "#ff2222^server_cosmetics_sunglasses_shine.png",
				},
				green = {
					append = true,
					color = "#22ff22^server_cosmetics_sunglasses_shine.png",
				},
				black = {
					append = true,
					color = "#000000^server_cosmetics_sunglasses_shine.png",
				},
				tournament = {
					append = true,
					color = "#000000^(server_cosmetics_sunglasses_shine.png^[multiply:#ffe346)",
				},
				blue_classic = {
					append = false,
					color = "#000000ff^server_cosmetics_new_year_sunglasses.png",
				},
			},
		},
		entity_cosmetics = {
			santa_hat = {
				_prefix = "Wear ",
				_description = "Christmas Hat",
				_model = "server_cosmetics_hat.b3d",
				_preview_rot = {350, 345},
				_preview_rot_offset = {y = 180},
				_preview_shift = {x = 0, y = -1.6},
				_preview_scale = 0.65,
				_anims = {
					idle = {x = 1, y = 1},
					bumpy = {x = 1, y = 14},
					falling = {x = 15, y = 23},
				},
				_date_start = 2021,
				["2021"] = {"server_cosmetics_santa_hat.png"},
				["2022"] = {"server_cosmetics_santa_hat.png^(server_cosmetics_santa_hat_overlay.png^[multiply:green)"},
				["2023"] = {"server_cosmetics_santa_hat.png^(server_cosmetics_santa_hat_overlay.png^[multiply:purple)"},
				["2024"] = {"server_cosmetics_santa_hat.png^(server_cosmetics_santa_hat_overlay.png^[multiply:blue)"},
			},

			map_creator_helmet = {
				_prefix = "Wear ",
				_description = "Map creator helmet",
				_model = "server_cosmetics_hat.b3d",
				_preview_rot = {350, 345},
				_preview_rot_offset = {y = 180},
				_preview_shift = {x = 0, y = -1.5},
				_preview_scale = 0.69,
				_anims = {
					idle = {x = 24, y = 24},
					bumpy = {x = 40, y = 40},
					falling = {x = 24, y = 40},

				},
				["normal"] = {"server_cosmetics_map_creator_helmet.png"},
			},

			hallows_hat = {
				_prefix = "Wear ",
				_description = "Hallows Hat",
				_model = "server_cosmetics_hat.b3d",
				_preview_rot = {350, 345},
				_preview_rot_offset = {y = 180},
				_preview_shift = {x = 0, y = -1.5},
				_preview_scale = 0.69,
				_anims = {
					idle = {x = 24, y = 27},
					bumpy = {x = 24, y = 32},
					falling = {x = 33, y = 41},
				},
				_date_start = 2022,
				["2022"] = {"server_cosmetics_hallows_hat.png^(server_cosmetics_hallows_hat_overlay.png^[multiply:#333)"},
				["2023"] = {"server_cosmetics_hallows_hat.png^(server_cosmetics_hallows_hat_overlay.png^[multiply:purple)"},
				["2024"] = {"server_cosmetics_hallows_hat.png^(server_cosmetics_hallows_hat_overlay.png^[multiply:red)"},
				["2025"] = {"server_cosmetics_hallows_hat.png^(server_cosmetics_hallows_hat_overlay.png^[multiply:#00d2ff)"},
			},
			crown = {
				_prefix = "Wear ",
				_description = "Crown",
				_model = "server_cosmetics_hat.b3d",
				_preview_rot = {350, 15},
				_preview_rot_offset = {y = 180},
				_preview_shift = {x = 0, y = -1.6},
				_preview_scale = 0.61,
				_anims = {
					idle = {x = 1, y = 1},
				},
				["normal"] = {"server_cosmetics_crown.png"},
			},
			party_hat = {
				_prefix = "Wear ",
				_description = "Party Hat",
				_model = "server_cosmetics_hat.b3d",
				_preview_rot = {350, 345},
				_preview_rot_offset = {y = 180},
				_preview_shift = {x = 0, y = -1.5},
				_preview_scale = 0.69,
				_anims = {
					idle = {x = 1, y = 1},
				},
				["anniversary"] = {"blank.png", "server_cosmetics_party_hat.png"},
			},
			straw_hat = {
				_prefix = "Wear ",
				_description = "Straw Hat",
				_model = "server_cosmetics_straw_hat.obj",
				-- _preview_rot = {350, 315},
				_preview_rot_offset = {y = 180},
				_preview_shift = {x = -0.35, y = -1.05},
				_preview_scale = 0.88,
				["normal"] = {"server_cosmetics_straw_hat.png"},
			},
		}
	}
}

local function copy_texture_list(src)
	local out = {}
	for i = 1, #src do
		out[i] = src[i]
	end

	return out
end

do
	local current_year_num = tonumber(os.date("%Y"))
	local current_year_key = tostring(current_year_num)

	for name, data in pairs(server_cosmetics.cosmetics.entity_cosmetics) do
		local date_start = data._date_start
		if date_start and current_year_num >= date_start and not data[current_year_key] then
			local fallback_year = current_year_num - 1

			while fallback_year >= date_start do
				local fallback = data[tostring(fallback_year)]
				if fallback then
					data[current_year_key] = copy_texture_list(fallback)
					core.log("warning",
						string.format(
							"[server_cosmetics] Missing %s variant for %d; reusing %d textures",
							name,
							current_year_num,
							fallback_year
						)
					)
					break
				end
				fallback_year = fallback_year - 1
			end
		end
	end
end

if os.date("%m/%d") == "04/01" then
	server_cosmetics.cosmetics.default_cosmetics.skin.smurf = "#0085e8"
end

core.after(0, function()
	for category, contents in pairs(server_cosmetics.cosmetics) do
		for ctype, cosmetics in pairs(contents) do
			for name, info in pairs(cosmetics) do
				if name:sub(1, 1) ~= "_" then
					if type(info) == "table" then
						if info[1] then
							server_cosmetics.cosmetics[category][ctype][name].color = {
								[1] = info[1],
								[2] = info[2] or "blank.png",
							}
						end

						server_cosmetics.cosmetics[category][ctype][name]._key = name
					elseif type(info) == "string" then
						server_cosmetics.cosmetics[category][ctype][name] = {
							_key = name,
							color = info,
						}
					end
				end
			end
		end
	end
end)

local function include(file)
	dofile(core.get_modpath(core.get_current_modname()).."/"..file)
end

include("hat.lua")
include("commands.lua")

local hatted = {}
function server_cosmetics.update_entity_cosmetics(player, current)
	player = PlayerObj(player)
	if not player then return end

	local pname = player:get_player_name()

	local hatname = false
	for key in pairs(current) do
		for cosmetic in pairs(server_cosmetics.cosmetics.entity_cosmetics) do
			if key == cosmetic then
				hatname = key
				break
			end
		end
	end

	if hatname then
		local hat = core.add_entity(player:get_pos(), "server_cosmetics:hat")

		local cdef = server_cosmetics.cosmetics.entity_cosmetics[hatname]
		hat:set_attach(player, "Head", vector.new(0, 2, 0))
		hat:set_properties({textures = current[hatname].color, mesh = cdef._model})
		hat:get_luaentity().animr = server_cosmetics.cosmetics.entity_cosmetics[hatname]._anims

		hatted[pname] = hat
	end
end

local old_set_extra_clothing = ctf_cosmetics.set_extra_clothing
function ctf_cosmetics.set_extra_clothing(player, ...)
	local ret = old_set_extra_clothing(player, ...)

	local pname = player:get_player_name()
	if hatted[pname] then
		hatted[pname]:remove()
		hatted[pname] = nil
	end

	server_cosmetics.update_entity_cosmetics(player, ctf_cosmetics.get_extra_clothing(player))

	return ret
end

local old_get_clothing_texture = ctf_cosmetics.get_clothing_texture
function ctf_cosmetics.get_clothing_texture(player, texture, ...)
	if texture == "skin" then
		return "server_cosmetics_skin.png"
	end

	for cosmetic in pairs(server_cosmetics.cosmetics.entity_cosmetics) do
		if texture == cosmetic then
			return false
		end
	end

	for cosmetic in pairs(server_cosmetics.cosmetics.headwear) do
		if texture == cosmetic then
			return server_cosmetics.cosmetics.headwear[cosmetic]._texture
		end
	end

	return old_get_clothing_texture(player, texture, ...)
end

core.register_on_joinplayer(function(player)
	local current = ctf_cosmetics.get_extra_clothing(player)

	if current._unset then
		ctf_cosmetics.set_extra_clothing(player, {
			hair = server_cosmetics.cosmetics.default_cosmetics.hair["brown"],
			eyes = server_cosmetics.cosmetics.default_cosmetics.eyes["blue"],
		})

		player_api.set_texture(player, 1, ctf_cosmetics.get_skin(player))
	end

	if server_cosmetics.no_entity_attach[player:get_player_name()] then
		return
	end
	core.after(1, server_cosmetics.update_entity_cosmetics, player:get_player_name(), current)
end)

core.register_on_leaveplayer(function(player)
	local pname = player:get_player_name()
	if hatted[pname] then
		hatted[pname]:remove()
		hatted[pname] = nil
	end
end)

ctf_api.register_on_new_match(function()
	core.after(5, function()
		for _, player in ipairs(core.get_connected_players()) do
			local pname = player:get_player_name()
			if not server_cosmetics.no_entity_attach[pname] then
				local hat = hatted[pname]
				if hat and not hat:get_pos() then
					server_cosmetics.update_entity_cosmetics(player, ctf_cosmetics.get_extra_clothing(player))
					core.log("action", "server_cosmetics: Hat entity for player " .. player:get_player_name() .. " unloaded. Re-adding... (on new match)")
				end
			end
		end
	end)
end)

-- Used for testing with //lua
-- Put through https://mothereff.in/lua-minifier before running
-- local ocu = server_cosmetics.can_use
-- function server_cosmetics.can_use(p, ...)
-- 	if p:get_player_name() == "LandarVargan" then
-- 		return true
-- 	else
-- 		return ocu(p, ...)
-- 	end
-- end

function server_cosmetics.can_use(player, clothing, color)
	if not color then return false end

	local meta = player:get_meta()

	if (server_cosmetics.cosmetics.default_cosmetics[clothing] and
	server_cosmetics.cosmetics.default_cosmetics[clothing][color]) or
	meta:get_int("server_cosmetics:entity:"..clothing..":"..color) ~= 0 or
	meta:get_int("server_cosmetics:headwear:"..clothing..":"..color) ~= 0 then
		return true
	else
		return false
	end
end

-- Legacy cosmetic format conversion
local old_get_extra_clothing = ctf_cosmetics.get_extra_clothing
function ctf_cosmetics.get_extra_clothing(player, ...)
	local pmeta = PlayerObj(player):get_meta()
	local meta = pmeta:get_string("ctf_cosmetics:extra_clothing")

	if meta ~= "" then
		meta = core.deserialize(meta)

		if not meta then
			pmeta:set_string("ctf_cosmetics:extra_clothing", "")

			return old_get_extra_clothing(player, ...)
		end

		for costype, color in pairs(meta) do

			-- Add compat for two entity materials
			if meta[costype] and costype == "santa_hat" or costype == "hallows_hat" then
				if type(color.color) == "string" then
					color.color = {color.color, "blank.png"}
					meta[costype] = color
				elseif type(color.color) == "table" and color.color[1] and color.color[1][1] then
					local temp = color.color

					repeat
						temp = temp[1]
					until not temp[1][1]

					color.color = temp
					meta[costype].color = temp
				end
			end

			if type(color) == "string" then
				local breakout = false

				for category, contents in pairs(server_cosmetics.cosmetics) do
					for ctype, cosmetics in pairs(contents) do
						for name, info in pairs(cosmetics) do
							if name:sub(1, 1) ~= "_" then
								if info.color == color then
									meta[costype] = info
									color = info
									breakout = true
									break
								end
							end
						end
						if breakout then break end
					end
					if breakout then break end
				end

				if not breakout then -- couldn't find the cosmetic, but it's in the wrong format, so remove it
					meta[costype] = nil
				end
			end

			-- Remove cosmetics players can no longer use
			if meta[costype] and not server_cosmetics.can_use(player, costype, color._key) then
				meta[costype] = nil
			end
		end

		pmeta:set_string("ctf_cosmetics:extra_clothing", core.serialize(meta))
	end

	return old_get_extra_clothing(player, ...)
end

include("inv_tab.lua")
include("graves.lua")
include("ranking_reset.lua")
