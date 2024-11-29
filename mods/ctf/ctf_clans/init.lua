-- * Copyright (c) 2024 Nanowolf4 (n4w@tutanota.com)
-- * SPDX-License-Identifier: GPL-3.0-or-later

local storage = minetest.get_mod_storage()

ctf_clans = {
	clans_ranking = {},
	max_id = 0,
	registered_clans = {},
}

local default_rank_icons = {
	"ctf_clans_owner.png",
	"ctf_clans_member.png"
}

local permissions = {
	owner = {"any"},
	mod = {"invite", "kick", "set_rank", "set_description"},
	member = {"invite"},
	guest = {}
}

local clans_data = {}

local clans_data_key = "clan_data:%d"
local registered_clans_key = "registered_clans"
local player_clan_id_key = "clan_id:"

local function get_clan_data(id)
	local this_clan = clans_data[id]
	if this_clan then
		return this_clan
	end
	local key = string.format(clans_data_key, id)
	if storage:contains(key) then
		-- minetest.log("action", "Loading clan data of " .. id .. " from modstorage")
		return minetest.deserialize(storage:get(key))
	end
	return nil
end

local function load_clan_data(id)
	local data = get_clan_data(id)
	if data ~= clans_data[id] then
		clans_data[id] = data
		minetest.log("action", "Clan data loaded: " .. id)
	elseif not data then
		return false
	end
	return true
end

ctf_clans.load_clan_data = load_clan_data

local function save_clan_data(id)
	local key = string.format(clans_data_key, id)
	local this_clan = clans_data[id]
	if this_clan then
		local serialized_data = minetest.serialize(this_clan)
		storage:set_string(key, serialized_data)
		minetest.debug("Saved clan data for: " .. id)
		return true
	end
	return false
end

local function delete_clan_data(id)
	storage:set_string(string.format(clans_data_key, id), nil)
end

local function save_registered_clans()
	local serialized_data = minetest.serialize(ctf_clans.registered_clans)
	storage:set_string(registered_clans_key, serialized_data)
end

function ctf_clans.get_clan_def(id)
	if load_clan_data(id) then
		return clans_data[id]
	end
	return nil
end

function ctf_clans.get_clan_name(id)
	local def = clans_data[id]
	return def.clan_name
end

function ctf_clans.is_clan_exist(id)
	if id and load_clan_data(id) and clans_data[id].clan_name then
		return true
	end
	return false
end

function ctf_clans.get_clan_id(player_name)
	local key = player_clan_id_key .. player_name
	if storage:contains(key) then
		local id = storage:get_int(key)
		if id > 0 then
			return id
		end
	end
end

function ctf_clans.is_any_members_online(id)
	if not clans_data[id] then
		return false
	end

	local members = clans_data[id].members
	for pn in pairs(members) do
		if minetest.get_player_by_name(pn) then
			return true
		end
	end

	return false
end

function ctf_clans.get_member_rank(id, player_name)
	local this_clan = clans_data[id]
	local member_def = this_clan.members[player_name]
	if member_def then
		return member_def.rank
	end
end

local function check_default_permissions(rank, action)
    local rank_permissions = permissions[rank]
    if not rank_permissions then
        return false
    end

    if rank_permissions[1] == "any" then
        return true
    end

    for _, permission in ipairs(rank_permissions) do
        if permission == action then
            return true
        end
    end

    return false
end

function ctf_clans.has_permission(id, player_name, action)
	local this_clan = clans_data[id]

	local rank_name = this_clan.members[player_name].rank
	if this_clan.owner == player_name then
		return true
	end

	if check_default_permissions(rank_name, action) then
		return true
	end

	local rank_def = this_clan.ranks[rank_name]

	if rank_def.permissions then
		for _, permission in ipairs(rank_def.permissions) do
			if permission == action then
				return true
			end
		end
	end

	return false
end

function ctf_clans.get_rank_icon(rank_def)
	if rank_def.icon_index then
		return default_rank_icons[rank_def.icon_index]
	elseif rank_def.icon then
		return rank_def.icon
	end
end

function ctf_clans.set_member_rank(id, member_name, new_rank)
	local this_clan = clans_data[id]
	local member_def = this_clan.members[member_name]
	local rank_def = this_clan.ranks[new_rank]
	if member_def and rank_def then
		-- if new_rank == "owner" then
		-- 	this_clan.owner = member_name
		-- end
		member_def.rank = new_rank
		return true
	end

	return false
end

function ctf_clans.create(player_name, def)
	local fields = {
		clan_name = def.clan_name or "Unknown",
		color = def.color or "FFFFFF",
		title = def.title,
		description = def.description or "",
		board = "",
		owner = def.owner,
		creation_time = os.time(),
		members = {[def.owner] = {rank = "owner"}},
		ranks = {
			owner = {icon_index = 1, permissions = {}},
			member = {icon_index = 2, permissions = {}},
			custom = {icon = "ctf_clans_random_color.png"},
			custom_test2 = {icon = "default_dirt.png"},
			guest = {}
		},
	}

	local new_id = ctf_clans.max_id + 1
	storage:set_int("max_id", new_id)
	ctf_clans.max_id = new_id

	clans_data[new_id] = fields
	table.insert(ctf_clans.registered_clans, new_id)
	save_clan_data(new_id)
	save_registered_clans()

	local key = player_clan_id_key .. player_name
	storage:set_int(key, new_id)

	minetest.debug("Player " .. def.owner .. " created a new clan: " .. def.clan_name .. " ID:" .. new_id)

	return new_id
end

function ctf_clans.remove_clan(id)
	for pn in pairs(clans_data[id].members) do
		local key = player_clan_id_key .. pn
		if storage:contains(key) then
			storage:set_int(key, 0)
			minetest.debug("Set clan_member to 0 of " .. pn)
		end
	end

	local regid = table.indexof(ctf_clans.registered_clans, id)
	if regid ~= -1 then
		table.remove(ctf_clans.registered_clans, regid)
		minetest.debug("Removed " .. regid .. " from the list of the registered clans")
	end

	clans_data[id] = nil
	delete_clan_data(id)
	save_registered_clans()

	minetest.debug("Clan " .. id .. " has been removed")
end

function ctf_clans.add_member(id, player_name)
	local this_clan = clans_data[id]
	if ctf_clans.get_clan_member(id, player_name) then
		minetest.debug("already member of the clan")
		return false
	end
	this_clan.members[player_name] = {rank = "member"}
	save_clan_data(id)
	local key = player_clan_id_key .. player_name
	storage:set_int(key, id)
	minetest.debug(player_name .. " joined the clan " .. this_clan.clan_name)
	return true
end

function ctf_clans.get_clan_member(id, player_name)
	local this_clan = ctf_clans.get_clan_def(id)
	if this_clan then
		if this_clan.members[player_name] then
			return this_clan.members[player_name]
		end
	end
end

function ctf_clans.remove_member(id, player_name)
	local this_clan = clans_data[id]
	if this_clan.owner == player_name then
		minetest.log("warning", "Clan owner attempt to leave own clan")
		return false
	end

	if this_clan.members[player_name] then
		this_clan.members[player_name] = nil
		save_clan_data(id)
		local key = player_clan_id_key .. player_name
		storage:set_int(key, 0)
		minetest.debug(player_name .. " left the clan " .. this_clan.clan_name)
		return true
	end
	return false
end

function ctf_clans.fix_entry(player_name)
	local id = ctf_clans.get_clan_id(player_name)
	if id and not load_clan_data(id) then
		local key = player_clan_id_key .. player_name
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
		local this_clan = clans_data[id]
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
		minetest.debug("clan data loaded: " .. id)
	end
end)

minetest.register_on_leaveplayer(function(player)
	local id = ctf_clans.get_clan_id(player:get_player_name())
	if id and id > 0 then
		save_clan_data(id)
		if not ctf_clans.is_any_members_online(id) then
			clans_data[id] = nil
			minetest.log("action", "Unloaded clan data ID: " .. id)
		end
	end
end)

minetest.register_on_mods_loaded(function()
	local max_id_key = "max_id"
	if storage:contains(max_id_key) then
		ctf_clans.max_id = storage:get_int(max_id_key)
	end

	local rc_key = registered_clans_key
	if storage:contains(rc_key) then
		ctf_clans.registered_clans = minetest.deserialize(storage:get(rc_key))
	end
end)

minetest.register_on_shutdown(function()
	for id, _ in pairs(clans_data) do
		if id > 0 then
			save_clan_data(id)
		end
	end
end)

local modpath = minetest.get_modpath(minetest.get_current_modname())
dofile(modpath .. "/chat_commands.lua")
dofile(modpath .. "/invitation.lua")
dofile(modpath .. "/clan_maker.lua")
dofile(modpath .. "/clan_ui.lua")
dofile(modpath .. "/formspec_helper.lua")