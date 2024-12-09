local pending_invites = {}
local cooldown = ctf_core.init_cooldowns()

function ctf_clans.invite_player(target_name, by, id)
	local fields = {
		clan_id = id,
		invitedby = by,
		-- time = os.time()
	}

	if not pending_invites[target_name] then
		pending_invites[target_name] = {[1] = fields}
	else
		table.insert(pending_invites[target_name], fields)
	end
	local last_index = #pending_invites[target_name]

	pending_invites[target_name][last_index].timer = minetest.after(3600, function()
		if minetest.get_player_by_name(by) then
			minetest.chat_send_player(by, minetest.colorize("red", "Invite has expired!"))
		end
		pending_invites[target_name][last_index] = nil
	end)

	local notify_msg = "You've been invited to join clan \"" .. ctf_clans.get_clan_name(id) .. "\"" ..
		"\nUse /accept " .. id .. " to join"

	minetest.chat_send_player(target_name, minetest.colorize("#00ff5d", notify_msg))

end

function ctf_clans.accept_invite(player_name, id)
	local index = ctf_clans.get_invite_index(player_name, id)
	if index then
		local invite = pending_invites[player_name][index]
		local target_id = invite.clan_id
		if ctf_clans.add_member(target_id, player_name) then
			invite.timer:cancel()
			pending_invites[player_name] = nil
			minetest.debug("Player accepted an invitation to: " .. target_id)
			return true
		end
	end
	minetest.debug("Failed to accept the invitation for unknown reason")
	return false
end

function ctf_clans.get_invite_index(player_name, id)
	local pending = pending_invites[player_name]
	if pending then
		for i, v in ipairs(pending) do
			if id == v.clan_id then
				return i
			end
		end
	end
end

minetest.register_chatcommand("invite",{
	description = "Invite a player to your clan",
	privs = {},
	params = "<player_name>",
	func = function(name, target_name)
		local player = minetest.get_player_by_name(name)
		if cooldown:get(player) then
			return false, "You can't invite too frequently"
		end

		local target = minetest.get_player_by_name(target_name)
		if not minetest.player_exists(target_name) then
			return false, "The player does not exist"
		end

		if name == target_name then
			return false, "You can't invite yourself. You want to break the system? Haha!"
		end

		local id = ctf_clans.get_clan_id(name)
		if not id or id == 0 or not ctf_clans.is_clan_exist(id) then
			return false, "You don't have a clan... First create a new one"
		end

		local def = ctf_clans.get_clan(id)

		if def.owner ~= name then
			return false, "You must be owner of the clan to invite a new members. Please contact to " .. def.owner
		end

		if ctf_clans.get_clan_member(id, target_name)then
			return false, "Player already a member of the \"" .. def.clan_name .. "\""
		end

		if ctf_clans.get_invite_index(target_name, id) then
			return false, target_name .. " already has been invited to " .. def.clan_name  ..
			".\nPlease wait until " .. target_name .. " accepts invitation (or not)."
		end

		ctf_clans.invite_player(target_name, name, id)
		cooldown:set(player, 60)
		return true, minetest.colorize("green", "Invitation has been sent to " .. target_name)
	end
})

local function get_pending_invites(name)
	local ids = {}
	for _, v in ipairs(pending_invites[name]) do
		local def = ctf_clans.get_clan(v.clan_id)
		if def then
			table.insert(ids, "[" .. def.clan_name .. "]: " .. v.clan_id .. " | Sender: " .. v.invitedby)
		end
	end
	return table.concat(ids, " ")
end

minetest.register_on_joinplayer(function(player)
	local name = player:get_player_name()
	if pending_invites[name] then
		local msg = minetest.colorize("#00ff5d", "You have clan invitation(s):\n" .. get_pending_invites(name) .. "\nUse /accept <id> to accept.")
		minetest.chat_send_player(player:get_player_name(), msg)
	end
end)

minetest.register_chatcommand("accept",{
	description = "Accept an invitation to the clan",
	privs = {},
	params = "<Clan ID>",
	func = function(name, id)
		id = tonumber(id)
		if not pending_invites[name] then
			return false, "No one has invited you yet"
		end
		if not id then
			return false, "Clan ID not provided. Example: /accept 12"
		end
		if ctf_clans.accept_invite(name, id) then
			return true, minetest.colorize("#00ff5d", "You have been successfully joined the clan. Congratulations!")
		else
			return false, "You did not receive an invitation to the clan [ID:" .. id .. "]" ..
				"\nYou have invitation to:\n" .. get_pending_invites(name)
		end
	end
})
