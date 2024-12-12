-- * Copyright (c) 2024 Nanowolf4 (n4w@tutanota.com)
-- * SPDX-License-Identifier: GPL-3.0-or-later

local storage = minetest.get_mod_storage()
local modpath = minetest.get_modpath(minetest.get_current_modname())

ctf_clans = {
	max_id = 0,
	registered_clans = {},
}

ctf_clans.reference = {
	clan_name = "Unknown",
	color = "white",
	description = "",
	board = "",
	owner = "",
	creation_time = 0,
	members = {},
	roles = {
		owner = {icon_index = 1, permissions = {}},
		member = {icon_index = 2, permissions = {}},
	},
}

if storage:contains("max_id") then
	ctf_clans.max_id = storage:get_int("max_id")
	minetest.log("action", "CTF_CLANS: MAX ID: " .. ctf_clans.max_id)
end

local default_role_icons = {
	"ctf_clans_owner.png",
	"ctf_clans_member.png",
	"ctf_clans_owner.png^[colorize:black:100",
}

local permissions = {
	owner = {"any"},
	mod = {"invite", "kick", "set_role", "clanboard_editor"}, --"set_description"
	member = {"invite", "clanboard_editor"},
	guest = {}
}

dofile(modpath .. "/clan_storage.lua")

local clans_context = {}
local player_clan_id_key = "id:%s"


local function load_clan_data(id)
	local this_clan = clans_context[id]

	if type(this_clan) == "table" and this_clan.clan_name then
		return true
	end

	if ctf_clans.storage.is_clan_data_exist(id) then
		this_clan = ctf_clans.storage.load_clan_data(id)
		clans_context[id] = this_clan

		minetest.log("action", "Clan data loaded: " .. id)
		return true
	end

	minetest.log("error", "Unable to upload a non-existent clan " .. id)
	return false
end

local function save_clan_data(id)
	local this_clan = clans_context[id]
	if this_clan then
		ctf_clans.storage.save_clan_data(id, this_clan)
		minetest.debug("Saved clan data for: " .. id)
		return true
	end
	return false
end

function ctf_clans.get_clan(id)
	if load_clan_data(id) then
		return clans_context[id]
	end
	return nil
end

function ctf_clans.get_clan_name(id)
	return clans_context[id].clan_name
end

function ctf_clans.is_clan_exist(id)
	if id and (clans_context[id] or ctf_clans.storage.is_clan_data_exist(id)) then
		return true
	end
	return false
end

function ctf_clans.get_clan_id(player_name)
	local key = string.format(player_clan_id_key, player_name)
	if storage:contains(key) then
		local id = storage:get_int(key)
		if id > 0 then
			return id
		end
	end
end

function ctf_clans.is_any_members_online(id)
	if not clans_context[id] then
		return false
	end

	local members = clans_context[id].members
	for pn in pairs(members) do
		if minetest.get_player_by_name(pn) then
			return true
		end
	end

	return false
end

function ctf_clans.player_is_clan_member(id, player_name)
	return clans_context[id] and clans_context[id].members[player_name] ~= nil
end

function ctf_clans.get_member_role(id, player_name)
	local this_clan = clans_context[id]
	local member_def = this_clan.members[player_name]
	if member_def then
		return member_def.role
	end
end

local function check_default_permissions(role, action)
	local role_permissions = permissions[role]
	if not role_permissions then
		return false
	end

	if role_permissions[1] == "any" then
		return true
	end

	for _, permission in ipairs(role_permissions) do
		if permission == action then
			return true
		end
	end

	return false
end

function ctf_clans.has_permission(id, player_name, action)
	local this_clan = clans_context[id]

	if not this_clan.members[player_name] then
		return false
	end

	local role_name = this_clan.members[player_name].role
	if this_clan.owner == player_name then
		return true
	end

	if check_default_permissions(role_name, action) then
		return true
	end
	local role_def = this_clan.roles[role_name]

	if role_def.permissions then
		for _, permission in ipairs(role_def.permissions) do
			if permission == action then
				return true
			end
		end
	end

	return false
end

function ctf_clans.get_role_icon(role_def)
	if role_def.icon_index then
		return default_role_icons[role_def.icon_index]
	elseif role_def.icon then
		return role_def.icon
	end
end

function ctf_clans.set_member_role(id, member_name, new_role)
	local this_clan = clans_context[id]
	local member_def = this_clan.members[member_name]
	local role_def = this_clan.roles[new_role]
	if member_def and role_def then
		-- if new_role == "owner" then
		-- 	this_clan.owner = member_name
		-- end
		member_def.role = new_role
		ctf_clans.storage.save_clan_member_data(id, this_clan, member_name)
		return true
	end

	return false
end

function ctf_clans.create(player_name, def)
	local new_clan = table.copy(ctf_clans.reference)
	new_clan.clan_name = def.clan_name or "Unknown"
	if def.color then
		new_clan.color = def.color
	end
	new_clan.title = def.title or ""
	if def.description then
		new_clan.description = def.description
	end
	new_clan.owner = def.owner
	new_clan.creation_time = os.time()
	new_clan.members[def.owner] = {role = "owner"}

	new_clan.roles.custom = {icon = "ctf_clans_random_color.png", ""}
	new_clan.roles.guest = {permissions = {}}

	local new_id = ctf_clans.max_id + 1
	storage:set_int("max_id", new_id)
	ctf_clans.max_id = new_id
	ctf_clans.storage.register_clan_id(new_id)

	clans_context[new_id] = new_clan
	table.insert(ctf_clans.registered_clans, new_id)
	save_clan_data(new_id)
	ctf_clans.storage.save_all_clan_member_data(new_id, new_clan)

	storage:set_int(string.format(player_clan_id_key, player_name), new_id)

	minetest.debug("Player " .. def.owner .. " created a new clan: " .. def.clan_name .. " ID:" .. new_id)

	return new_id
end

function ctf_clans.remove_clan(id)
	for pn in pairs(clans_context[id].members) do
		local key = string.format(player_clan_id_key, pn)
		if storage:contains(key) then
			storage:set_int(key, 0)
			minetest.debug("Set clan_member to 0 of " .. pn)
		end
	end

	clans_context[id] = nil
	ctf_clans.storage.purge_clan_data(id)

	minetest.debug("Goodbye " .. id .. " :(" )
end

function ctf_clans.add_member(id, player_name)
	local this_clan = clans_context[id]
	if ctf_clans.get_clan_member(id, player_name) then
		minetest.debug("already member of the clan")
		return false
	end
	this_clan.members[player_name] = {role = "member"}
	save_clan_data(id)
	storage:set_int(string.format(player_clan_id_key, player_name), id)
	ctf_clans.storage.new_member(id, this_clan, player_name)
	minetest.debug(player_name .. " joined the clan " .. this_clan.clan_name)
	return true
end

function ctf_clans.get_clan_member(id, player_name)
	local this_clan = ctf_clans.get_clan(id)
	if this_clan then
		if this_clan.members[player_name] then
			return this_clan.members[player_name]
		end
	end
end

function ctf_clans.remove_member(id, player_name)
	local this_clan = clans_context[id]
	if this_clan.owner == player_name then
		minetest.log("warning", "Clan owner attempt to leave own clan")
		return false
	end

	if this_clan.members[player_name] then
		this_clan.members[player_name] = nil
		storage:set_int(string.format(player_clan_id_key, player_name), 0)
		ctf_clans.storage.remove_member(id, player_name)
		minetest.debug(player_name .. " left the clan " .. this_clan.clan_name)
		return true
	end
	return false
end

function ctf_clans.fix_entry(player_name)
	local id = ctf_clans.get_clan_id(player_name)
	if id then
		local key = string.format(player_clan_id_key, player_name)
		if storage:contains(key) then
			storage:set_int(key, 0)
			minetest.log("action", "removing non-existent clan id of " .. player_name)
			return true
		end
	end
	return false
end

function ctf_clans.get_chat_prefix(player_name)
	local id = ctf_clans.get_clan_id(player_name)
	if id and ctf_clans.is_clan_exist(id) then
		local this_clan = clans_context[id]
		local prefix = this_clan.prefix or this_clan.clan_name
		return {
			prefix = "[" .. prefix .. "]",
			color = this_clan.color
		}
	end
end

minetest.register_on_joinplayer(function(player)
	local player_name = player:get_player_name()
	local id = ctf_clans.get_clan_id(player_name)
	if not id then
		minetest.debug(player_name .. "(id) is not in the clan")
		return
	end
	if ctf_clans.is_clan_exist(id) then -- Load the clan data
		clans_context[id] = ctf_clans.storage.load_clan_data(id)
		minetest.debug("Clan data loaded: " .. id)
	end
end)

minetest.register_on_leaveplayer(function(player)
	local id = ctf_clans.get_clan_id(player:get_player_name())
	if id then
		if not ctf_clans.is_any_members_online(id) then
			clans_context[id] = nil
			minetest.log("action", "Unloaded clan data ID: " .. id)
		end
	end
end)

minetest.register_chatcommand("clans_forcesave",{
	description = "Save the clan data",
	privs = {server = true},
	params = "<id>",
	func = function(_, param)
		local id = tonumber(param)
		if not id then
			return false, "Clan ID required!"
		end

		local this_clan = clans_context[id]
		if not this_clan then
			return true, "This clan does not exist or is not loaded"
		end

		ctf_clans.storage.save_all_clan_member_data(id, this_clan)
		ctf_clans.storage.save_clan_data(id, this_clan)
		return true, "Saved"
	end
})

minetest.register_chatcommand("clans_forceload",{
	description = "Load the clan data",
	privs = {server = true},
	params = "<id>",
	func = function(_, param)
		local id = tonumber(param)
		if not id then
			return false, "Clan ID required!"
		end

		if load_clan_data(id) then
			return true, "Loaded"
		end

		return true, "Failed to load"
	end
})

dofile(modpath .. "/chat_commands.lua")
dofile(modpath .. "/invitation.lua")
dofile(modpath .. "/clan_maker.lua")
dofile(modpath .. "/clan_ui.lua")
dofile(modpath .. "/formspec_helper.lua")