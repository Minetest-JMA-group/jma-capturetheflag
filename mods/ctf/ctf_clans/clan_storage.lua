-- * Copyright (c) 2024 Nanowolf4 (n4w@tutanota.com)
-- * SPDX-License-Identifier: GPL-3.0-or-later

ctf_clans.storage = {}
local storage = minetest.get_mod_storage()

local members_list_cache = {}
local registered_clans_cache = {}

local clan_ctx_key = "ctx:%d"
local ml_key = "%d:members_list"
local registered_ids_key = "registered_ids"

function ctf_clans.storage.get_registered_ids()
	local list = registered_clans_cache
	if #list > 0 then
		return list
	end

	list = minetest.deserialize(storage:get_string(registered_ids_key))
	if not list then
		list = {}
	end
	return list
end

ctf_clans.storage.get_registered_ids()

function ctf_clans.storage.register_clan_id(id)
	local list = ctf_clans.storage.get_registered_ids()

	if table.indexof(list, id) == -1 then
		table.insert(list, id)
		storage:set_string(registered_ids_key, minetest.serialize(list))
		return true
	else
		minetest.log("warning", id .. " is already registered")
	end
	return false
end

local function unregister_clan_id(id)
	local list = ctf_clans.storage.get_registered_ids()
	local index = table.indexof(list, id)
	if index == -1 then
		minetest.log("error", "Attempting to remove a non-existent clan id: " .. id)
		return false
	end

	table.remove(list, index)
	if #list == 0 then
		storage:set_string(registered_ids_key, "")
	else
		storage:set_string(registered_ids_key, minetest.serialize(list))
	end
end

function ctf_clans.storage.get_members_list(id)
	local list = members_list_cache[id]
	if list then
		return list
	end

	list = minetest.deserialize(storage:get_string(string.format(ml_key, id)))
	if not list then
		list = {}
	end
	return list
end

local function members_list_add(id, player_name)
	local list = ctf_clans.storage.get_members_list(id)

	if table.indexof(list, player_name) == -1 then
		table.insert(list, player_name)
		storage:set_string(string.format(ml_key, id), minetest.serialize(list))
		return true
	else
		minetest.log("warning", "Player " .. player_name .. " is already in members list of clan " .. id)
	end
	return false
end

local function members_list_remove(id, player_name)
	local list = ctf_clans.storage.get_members_list(id)
	local index = table.indexof(list, player_name)
	if index == -1 then
		minetest.log("error", "Player " .. player_name .. " is not a member of clan " .. id)
		return false
	end

	table.remove(list, index)
	if #list == 0 then
		storage:set_string(string.format(ml_key, id), "")
	else
		storage:set_string(string.format(ml_key, id), minetest.serialize(list))
	end
end

function ctf_clans.storage.new_member(id, clan_data, player_name)
	local members_list = ctf_clans.storage.get_members_list(id)
	if table.indexof(members_list, player_name) ~= -1 then
		-- minetest.log("error", "Player " .. player_name .. " is already a member of clan " .. id)
		return false
	end

	if members_list_add(id, player_name) then
		minetest.log("action", "New member added to clan " .. id .. ": " .. player_name)
	end

	ctf_clans.storage.save_clan_member_data(id, clan_data, player_name)
	return true
end

function ctf_clans.storage.remove_member(id, player_name)
	minetest.debug("Removing member from clan", id, player_name)
	if members_list_remove(id, player_name) then

		-- Deleting member data
		storage:set_string(string.format("%d:member:%s", id, player_name), "")
		minetest.log("action", "Member removed from clan " .. id .. ": " .. player_name)
		return true
	end
	return false
end

function ctf_clans.storage.save_clan_member_data(id, clan_data, member_name)
	minetest.debug("Saving clan member data", id, member_name)
	if not ctf_clans.player_is_clan_member(id, member_name) then
		minetest.log("error", "Failed to save! " .. member_name .. " is not a member of clan" .. id)
		return false
	end
	local mctx = clan_data.members[member_name]
	if not mctx then
		minetest.log("error", "Attempt to save non-existent clan member " .. member_name)
		return false
	end

	ctf_clans.storage.new_member(id, clan_data, member_name)

	storage:set_string(string.format("%d:member:%s", id, member_name), minetest.serialize(mctx))

	return true
end

function ctf_clans.storage.save_all_clan_member_data(id, clan_data)
	minetest.debug("Saving all clan member data", id)
	for member_name, v in pairs(clan_data.members) do
		if ctf_clans.storage.new_member(id, clan_data, member_name) then
			storage:set_string(string.format("%d:member:%s", id, member_name), minetest.serialize(v))
			minetest.log("action", "Member data saved for " .. member_name)
		end
	end
end

function ctf_clans.storage.save_clan_data(id, clan_data)
	minetest.debug("Saving clan data", id)
	local ctx_copy = table.copy(clan_data)
	ctx_copy.members = nil

	storage:set_string(string.format(clan_ctx_key, id), minetest.serialize(ctx_copy))
end

function ctf_clans.storage.load_member_data(id, key)
	minetest.debug("Loading clan member data", id, key)
	local serialized_data = storage:get_string(string.format("%d:member:%s", id, key))
	local mctx = minetest.deserialize(serialized_data)
	if type(mctx) == "table" then
		return mctx
	else
		minetest.log("error", "Failed to load clan member " .. key)
		return nil
	end
end

function ctf_clans.storage.load_all_clan_members(id)
	minetest.debug("Loading all clan member data", id)
	local members = {}
	for _, k in ipairs(ctf_clans.storage.get_members_list(id)) do
		members[k] = ctf_clans.storage.load_member_data(id, k)
	end
	return members
end

function ctf_clans.storage.load_clan_member_data(id, member_name)
	minetest.debug("Loading clan member data", id, member_name)
	return ctf_clans.storage.load_member_data(id, member_name)
end

function ctf_clans.storage.load_clan_data(id)
	minetest.debug("Loading clan data", id)
	local ctx_data = minetest.deserialize(storage:get_string(string.format(clan_ctx_key, id))) or {}
	if not ctx_data then
		minetest.log("error", "Failed to deserialize clan data " .. id)
	end

	ctx_data.members = ctf_clans.storage.load_all_clan_members(id)

	-- Restoring required fields
	-- Questionable idea...
	for ref_name, ref_value in pairs(ctf_clans.reference) do
		if not ctx_data[ref_name] then
			ctx_data[ref_name] = ref_value
			minetest.log("warning", "Restored missing required field '" .. ref_name .. "' with default value")
		end
	end
	print(dump(ctx_data))
	return ctx_data
end

function ctf_clans.storage.purge_clan_data(id)
	if not ctf_clans.storage.is_clan_data_exist(id) then
		minetest.log("error", "Clan " .. id .. " does not exist")
		return false
	end

	-- Deleting clan data
	storage:set_string(string.format(clan_ctx_key, id), "")

	-- Deleting members data
	local members_list = ctf_clans.storage.get_members_list(id)
	for _, member_name in ipairs(members_list) do
		storage:set_string(string.format("%d:member:%s", id, member_name), "")
	end
	members_list_cache[id] = nil

	-- Deleting members list
	storage:set_string(string.format(ml_key, id), "")
	unregister_clan_id(id)

	minetest.log("action", "Clan " .. id .. " deleted.")
	return true
end

-- Checking the existence of a clan member
function ctf_clans.storage.is_clan_member_data_exist(id, player_name)
	local list = ctf_clans.storage.get_members_list(id)
	if table.indexof(list, player_name) ~= -1 then
		return true
	end
	return false
end

-- Checking the existence of the clan
function ctf_clans.storage.is_clan_data_exist(id)
	return storage:contains(string.format(clan_ctx_key, id))
end