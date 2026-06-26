-- SPDX-License-Identifier: LGPL-2.1-or-later
--- Copyright (c) 2026 Farooq Karimi Zadeh fkz at riseup dot net

--- @alias RestrictedItems { [string]: boolean }

--- @type { [PlayerName]: RestrictedItems }
local restriction_table = {}

restrict_item = {}

--- @param pname PlayerName
--- @param item string
function restrict_item.restict_for_player(pname, item)
	if not restriction_table[pname] then
		restriction_table = {}
	end
	restriction_table[pname][item] = true
end

--- @param pname PlayerName
--- @param item string
--- @return boolean
function restrict_item.is_restricted_for_player(pname, item)
	if not restriction_table[pname] then
		return false
	end
	return restriction_table[pname][item] or false
end

--- @param pname PlayerName
function restrict_item.clear_restrictions_for_player(pname)
	restriction_table[pname] = {}
end

function restrict_item.clear_all_restrictions()
	restriction_table = {}
end
