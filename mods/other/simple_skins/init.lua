-- Enhanced Simple Skins mod for Luanti
-- Provides a comprehensive skin management solution with support for private skin collections, compatibility with previous versions, and better inventory page.
-- Remade by Nanowolf4 (n4w@tutanota.com), originally developed by TenPlus1 and Zeg9
-- The code is licensed under the MIT license.

-- Load support for translation.
local S = core.get_translator("simple_skins")
local storage = core.get_mod_storage()

local player_skin_key = "skin:%s"
local player_collection_key = "player_collection:%s"

skins = {
	catalog = {},
	max_skin_id = 0, -- Used to get the last Skin ID
	skins = {},
	default_skin = 6
}

local sorted_skin_ids_public = {}
local player_collections = {}

-- Load skin list and metadata
do
	local catalog = dofile(core.get_modpath("simple_skins") .. "/skins_list.lua")
	if not catalog then
		core.log("error", "[simple_skins] Failed to load skins list.")
		catalog = {}
	end

	skins.catalog = catalog

	-- Cache sorting for better performance
	local sorted_skin_ids = {}
	local i = 1
	for skin_id, meta in pairs(catalog) do
		if not meta.private then
			sorted_skin_ids[i] = skin_id
			skins.max_skin_id = i
			i = i + 1
		end
	end

	table.sort(sorted_skin_ids, function(a, b) return catalog[a].name < catalog[b].name end)
	sorted_skin_ids_public = sorted_skin_ids
end

function skins.get_skin(name, skin_id)
	skin_id = skin_id or skins.skins[name]
	local catalog = skins.catalog
	if skin_id and catalog[skin_id] then
		if catalog[skin_id].texture then
			return catalog[skin_id].texture
		else -- Backward compatibility with the old simple skins
			return "character_" .. tostring(skin_id) .. ".png"
		end
	end
	return "character_" .. skins.default_skin .. ".png"
end

function skins.set_player_skin(name, skin_id, no_save)
	if not skins.catalog[skin_id] then
		return false, "Skin ID does not exist in the catalog."
	end

	if skins.skins[name] == skin_id then
		return false, "Skin ID " .. skin_id .. " is already set"
	end

	skins.skins[name] = skin_id
	skins.update_player_skin(core.get_player_by_name(name))

	if not no_save then
		storage:set_int(player_skin_key:format(name), skin_id)
	end

	return true, "Skin changed to ID " .. skin_id
end

function skins.get_player_collection(name)
	local player_collection = player_collections[name]
	if not player_collection then
		local serialized = storage:get_string(player_collection_key:format(name))

		if serialized ~= "" then
			player_collection = core.deserialize(serialized)
			if not player_collection then
				core.log("error", "[simple_skins] Failed to deserialize collection for player: " .. name)
				player_collection = {}
			end
		else
			player_collection = {}
		end

		-- Caching collections
		player_collections[name] = player_collection
	end

	return player_collection
end

function skins.save_player_collection(name)
	local player_collection = player_collections[name]

	if type(player_collection) ~= "table" then
		core.log("error", "[simple_skins] Failed to save collection for player: " .. name .. ". Invalid collection format " .. dump(player_collection))
		return false
	end

	local serialized = core.serialize(player_collection)
	storage:set_string(player_collection_key:format(name), serialized)

	core.log("action", "[simple_skins] Collection saved for player: " .. name)
	return true
end

function skins.add_skin_to_collection(name, skin_id)
	local player_collection = skins.get_player_collection(name)

	if table.indexof(player_collection, skin_id) ~= -1 then
		return false, "Skin ID already in the collection."
	end

	table.insert(player_collection, skin_id)
	player_collections[name] = player_collection
	skins.save_player_collection(name)

	core.log("action", "[simple_skins] Skin ID " .. skin_id .. " added to the collection of player: " .. name)
	return true
end

function skins.remove_skin_from_collection(name, skin_id)
	local player_collection = skins.get_player_collection(name)

	local index = table.indexof(player_collection, skin_id)
	if index == -1 then
		return false, "Skin ID not found in the collection."
	end

	table.remove(player_collection, index)
	player_collections[name] = player_collection
	skins.save_player_collection(name)

	core.log("action", "[simple_skins] Skin ID " .. skin_id .. " removed from the collection of player: " .. name)
	return true
end

function skins.check_and_clean_player_collection(name)
	local player_collection = skins.get_player_collection(name)
	local valid_collection = {}
	local collection_changed = false

	for _, skin_id in ipairs(player_collection) do
		if skins.catalog[skin_id] then
			table.insert(valid_collection, skin_id)
		else
			collection_changed = true
			core.log("action", "[simple_skins] Removed invalid skin ID " .. skin_id .. " from player: " .. name .. "'s collection.")
		end
	end

	if collection_changed then
		player_collections[name] = valid_collection
		skins.save_player_collection(name)
		core.chat_send_player(name, S("Error: Your skin collection contained invalid skins. They have been removed."))
	end
end

-- Update player skin
local is_player_api_exists = core.global_exists("player_api")
local is_ctf_cosmetics_exists = core.global_exists("ctf_cosmetics")
function skins.update_player_skin(player)
	if not player then return end
	local name = player:get_player_name()

	-- is the current skin exist?
	local skin_id = skins.skins[name]
	if not skins.catalog[skin_id] then
		core.chat_send_player(name, S("Error: Your current skin (ID:" .. dump(skin_id) .. ") is invalid. Applying default skin."))
		skins.skins[name] = skins.default_skin
		skin_id = skins.default_skin
	end

	if is_player_api_exists then
		player_api.set_textures(player, {skins.get_skin(name)})
		if is_ctf_cosmetics_exists then
			player_api.set_texture(player, 1, ctf_cosmetics.get_skin(player))
		end
	else
		default.player_set_textures(player, {skins.get_skin(name)})
	end
end

-- Load player skin on join
core.register_on_joinplayer(function(player)
	local name = player:get_player_name()
	if not name then return end

	-- Check for backward compatibility with Simple Skins
	local meta = player:get_meta()
	local old_skin = meta:get_string("simple_skins:skin")
	if old_skin and old_skin ~= "" then
		local skin_id = tonumber(old_skin:match("character_(%d+)"))
		if skin_id then
			skins.set_player_skin(name, skin_id)
			core.log("action", "[simple_skins] Converted old skin data for player: " .. name .. " to skin ID " .. skin_id)
		end
		-- Purge the old attribute
		meta:set_string("simple_skins:skin", "")
	else
		local skin_id = storage:get_int(player_skin_key:format(name))
		skins.check_and_clean_player_collection(name)

		-- Do we already have a skin in mod storage?
		if skin_id and skin_id > 0 then
			skins.set_player_skin(name, skin_id, true)
		else
			skins.skins[name] = skins.default_skin
		end
	end

	skins.update_player_skin(player)
end)

core.register_on_leaveplayer(function(player)
	local name = player:get_player_name()
	if skins.skins[name] then
		skins.skins[name] = nil
	end
end)

sfinv.register_page("simple_skins:skins", {
	title = S("Skins"),
	on_enter = function(self, player, context)
		-- Initialize context when entering the page
		context.skins = {
			show_player_collection = "false",
			selected_skin_id = skins.skins[player:get_player_name()]
		}
	end,
	on_leave = function(self, player, context)
		-- Clear context when leaving the page
		context.skins = nil
	end,
	get = function(self, player, context)
		-- Build formspec for skin selection
		local sctx = context.skins
		local formspec = "label[.5,2;" .. S("Select Player Skin:") .. "]"
		.. "checkbox[.5,1.4;show_player_collection;" .. S("Show my collection") .. ";" .. sctx.show_player_collection .. "]"
		.. "textlist[.5,2.5;6.8,6;skins_set;"

		local name = player:get_player_name()
		local skins_list = sorted_skin_ids_public
		if sctx.show_player_collection == "true" then
			skins_list = skins.get_player_collection(name)
			sctx.skins_list = skins_list
		end
		local skins_list_len = #skins_list

		local selected_index = 1
		for i, skin_id in ipairs(skins_list) do
			local skin_data = skins.catalog[skin_id]
			if skin_data then
				formspec = formspec .. skin_data.name or "ID: " .. tostring(skin_id)

				if skin_id == sctx.selected_skin_id then
					selected_index = i
				end

				if i < skins_list_len then
					formspec = formspec .. ","
				end
			end
		end

		formspec = formspec .. ";" .. tostring(selected_index) .. ";true]"

		local meta = skins.catalog[sctx.selected_skin_id]
		if meta then
			if meta.name then
				formspec = formspec .. "label[2,.5;" .. S("Name: ") .. meta.name .. "]"
			end

			if meta.author then
				formspec = formspec .. "label[2,1;" .. S("Author: ") .. meta.author .. "]"
			end
		end

		formspec = formspec .. "model[6,-0.2;1.5,3;player;character.b3d;"
		.. skins.get_skin(name, sctx.selected_skin_id) .. ";0,180;false;true]"
		.. "button[.5,8.5;2,1;apply_skin;" .. S("Apply") .. "]"
		.. "label[2,0;" .. S("Current Skin: ") .. skins.catalog[skins.skins[name]].name .. "]"

		return sfinv.make_formspec(player, context, formspec)
	end,
	on_player_receive_fields = function(self, player, context, fields)
		-- Handle checkbox toggle for showing player collection or public skins
		local sctx = context.skins
		if fields.show_player_collection then
			sctx.show_player_collection = fields.show_player_collection
			sctx.selected_skin_id = skins.skins[player:get_player_name()]
			return true, true
		end

		local event = core.explode_textlist_event(fields["skins_set"])
		if event.type == "CHG" then
			local name = player:get_player_name()
			local skins_list = sorted_skin_ids_public
			if sctx.show_player_collection == "true" then
				skins_list = sctx.skins_list
			end
			local skin_id = skins_list[event.index]
			if not skin_id or not skins.catalog[skin_id] then return true end

			-- Save the current selection in the context
			sctx.selected_skin_id = skin_id

			-- Refresh the current page
			return true, true
		end

		-- Apply the selected skin when "Apply" button is pressed
		if fields.apply_skin then
			local name = player:get_player_name()
			local skin_id = sctx.selected_skin_id
			if skin_id and skins.catalog[skin_id] then
				skins.set_player_skin(name, skin_id)
				core.chat_send_player(name, S("Your skin has been changed to: ") .. skins.catalog[skin_id].name)
			end
			return true, true
		end
	end,
})

core.register_chatcommand("skin_collection", {
	params = "<add/remove/show> <skin_id> [player_name]",
	description = "Manage a player's skin collection. Use 'add <skin_id>' to add a skin, 'remove <skin_id>' to remove a skin, or 'show' to view a player's collection.",
	privs = {server = true},
	func = function(name, param)
		local args = string.split(param, " ")

		if #args < 2 then
			return false, "Invalid usage. Correct format: /skin_collection <add/remove/show> <skin_id> [player_name]"
		end

		local action = args[1]
		local skin_id = tonumber(args[2])
		local target_name = args[3] or name

		if not skin_id and action ~= "show" then
			return false, "Invalid skin ID. Please provide a numeric ID for add/remove actions."
		end

		if not core.player_exists(name) then
			return false, "Player doesn't exist."
		end

		if action == "add" then
			local success, message = skins.add_skin_to_collection(target_name, skin_id)
			if success then
				return true, "Skin ID " .. skin_id .. " successfully added to " .. target_name .. "'s collection!"
			else
				return false, message
			end
		elseif action == "remove" then
			local success, message = skins.remove_skin_from_collection(target_name, skin_id)
			if success then
				return true, "Skin ID " .. skin_id .. " successfully removed from " .. target_name .. "'s collection!"
			else
				return false, message
			end
		elseif action == "show" then
			local collection = skins.get_player_collection(target_name)
			if #collection == 0 then
				return true, target_name .. " has no skins in their collection."
			end
			local collection_list = "Collection for " .. target_name .. ": "
			for i, skin_id in ipairs(collection) do
				local skin = skins.catalog[skin_id]
				if skin then
					collection_list = collection_list .. skin.name .. " (ID: " .. skin_id .. "), "
				end
			end
			return true, collection_list:sub(1, -3)
		else
			return false, "Invalid action. Use 'add' to add a skin, 'remove' to remove a skin, or 'show' to view a player's collection."
		end
	end,
})

core.register_chatcommand("set_skin", {
	params = "<skin_id> [player_name]",
	description = "Change the skin of a player. Specify a skin ID and optionally a player name.",
	privs = {server = true},
	func = function(name, param)
		local args = string.split(param, " ")

		if #args < 1 or #args > 2 then
			return false, "Invalid usage. Correct format: /set_skin <skin_id> [player_name]"
		end

		local skin_id = tonumber(args[1])
		if not skin_id then
			return false, "Invalid skin ID. Please provide a numeric ID."
		end

		local target_name = args[2] or name

		if not core.player_exists(target_name) then
			return true, "Player doesn't exist."
		end

		local success, message = skins.set_player_skin(target_name, skin_id)
		return success, message
	end,
})

core.register_chatcommand("skin_catalog", {
	params = "",
	description = "Show the entire catalog of skins.",
	privs = {server = true},
	func = function(name, _)
		local msg_list = {"Skins Catalog:\n"}
		for skin_id, skin_data in pairs(skins.catalog) do
			table.insert(msg_list, "ID: " .. skin_id .. " " .. dump(skin_data):gsub("\n", ""))
		end

		-- Split the message into chunks if it exceeds 255 characters
		for _, chunk in ipairs(core.wrap_text(msg_list, 255)) do
			core.chat_send_player(name, chunk)
		end

		return true
	end,
})