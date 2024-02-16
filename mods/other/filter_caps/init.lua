-- SPDX-License-Identifier: GPL-3.0-or-later
-- Copyright (c) 2023 Marko Petrović
local MP = minetest.get_modpath(minetest.get_current_modname())
local ie = minetest.request_insecure_environment()
local libinit, err = ie.package.loadlib(MP.."/mylibrary.so", "luaopen_mylibrary")
if not libinit and err then
	minetest.log("[filter_caps]: Failed to load shared object file")
	minetest.log("[filter_caps]: "..err)
else
	libinit()
end
