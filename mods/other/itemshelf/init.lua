-- Modified version of Itemshelf (https://github.com/hkzorman/itemshelf) by Zorman2000
-- Adapted for the JMA Elysium mod by Nanowolf4 (n4w@tutanota.com) | License: MIT

local modpath = core.get_modpath("itemshelf")

-- Load files
dofile(modpath .. "/api.lua")
dofile(modpath .. "/nodes.lua")


local admin_key_def = table.copy(core.registered_tools["default:axe_diamond"])
admin_key_def.groups = {}
admin_key_def.description = "Itemshelf admin key"
admin_key_def.inventory_image = "keys_key_skeleton.png^[colorize:#00ff00aa"

core.register_tool("itemshelf:admin_key", admin_key_def)
