---@meta

--- Luanti (formerly Minetest) Core API
---@class CoreAPI
---@field PLAYER_MAX_HP_DEFAULT integer  -- default maximum player hit points (usually 20)
core = {}

--- Get the current world path
---@return string
function core.get_worldpath() end

--- Create a directory
---@param path string
---@return boolean success
function core.mkdir(path) end

--- Schedule a function to run after delay
---@param delay number
---@param func function
function core.after(delay, func) end

--- Request server shutdown
---@param message? string
---@param reconnect? boolean
---@param delay? number
function core.request_shutdown(message, reconnect, delay) end

--- Get current mod name
---@return string
function core.get_current_modname() end

--- Get player privileges
---@param player_name string
---@return table<string, boolean>
function core.get_player_privs(player_name) end

--- Log a message
---@param level string "error"|"warning"|"action"|"info"|"verbose"
---@param message string
function core.log(level, message) end

--- Show formspec to player
---@param player_name string
---@param formname string
---@param formspec string
function core.show_formspec(player_name, formname, formspec) end

--- Escape string for formspec
---@param str string
---@return string
function core.formspec_escape(str) end

--- Handle async operations
---@param func function
function core.handle_async(func) end

--- Register a chat command
---@param name string
---@param definition table
function core.register_chatcommand(name, definition) end

--- Get mod path
---@param modname string
---@return string|nil
function core.get_modpath(modname) end

--- Get mod storage (persistent per mod)
---@param modname string
---@return ModStorage
function core.get_mod_storage(modname) end

--- Get server uptime
---@return number microseconds
function core.get_us_time() end

--- Get game time
---@return number seconds
function core.get_gametime() end

--- Get server version
---@return {string: string, number: number}
function core.get_version() end

--- Register node
---@param name string
---@param definition table
function core.register_node(name, definition) end

--- Register tool
---@param name string
---@param definition table
function core.register_tool(name, definition) end

--- Register craft item
---@param name string
---@param definition table
function core.register_craftitem(name, definition) end

--- Register entity
---@param name string
---@param definition table
function core.register_entity(name, definition) end

--- Register ABM (Active Block Modifier)
---@param definition table
function core.register_abm(definition) end

--- Register LBM (Loading Block Modifier)
---@param definition table
function core.register_lbm(definition) end

--- Register on_joinplayer callback
---@param func fun(player: ObjectRef)
function core.register_on_joinplayer(func) end

--- Register on_leaveplayer callback
---@param func fun(player: ObjectRef, timed_out: boolean)
function core.register_on_leaveplayer(func) end

--- Register on_chat_message callback
---@param func fun(name: string, message: string)
function core.register_on_chat_message(func) end

--- Register globalstep callback
---@param func fun(dtime: number)
function core.register_globalstep(func) end

--- Get connected players
---@return ObjectRef[]
function core.get_connected_players() end

--- Get player by name
---@param name string
---@return ObjectRef|nil
function core.get_player_by_name(name) end

--- Check if player exists
---@param name string
---@return boolean
function core.player_exists(name) end

--- Get node at position
---@param pos vector
---@return {name: string, param1: integer, param2: integer}
function core.get_node(pos) end

--- Set node at position
---@param pos vector
---@param node {name: string, param1?: integer, param2?: integer}
function core.set_node(pos, node) end

--- Add particle
---@param definition table
function core.add_particle(definition) end

--- Add particle spawner
---@param definition table
function core.add_particlespawner(definition) end

--- Play sound at position
---@param spec table
---@return number handle
function core.sound_play(spec) end

--- Registered items table
---@type table<string, table>
core.registered_items = {}

--- Registered nodes table
---@type table<string, table>
core.registered_nodes = {}

--- Registered tools table
---@type table<string, table>
core.registered_tools = {}

--- Registered craft items table
---@type table<string, table>
core.registered_craftitems = {}

--- Registered aliases table
---@type table<string, table>
core.registered_aliases = {}

--- Registered entities table
---@type table<string, table>
core.registered_entities = {}

--- Settings object
---@class Settings
core.settings = {}

--- Get setting value
---@param name string
---@param default any
---@return any
function core.settings:get(name, default) end

--- Get boolean setting
---@param name string
---@param default boolean
---@return boolean
function core.settings:get_bool(name, default) end

--- Get number setting
---@param name string
---@param default number
---@return number
function core.settings:get_num(name, default) end

--- Chat functions
---@param message string
function core.chat_send_all(message) end

---@param player_name string
---@param message string
function core.chat_send_player(player_name, message) end

--- Colorize text
---@param color string
---@param text string
---@return string
function core.colorize(color, text) end

--- Compress data
---@param data string
---@param method? string
---@param level? integer
---@return string
function core.compress(data, method, level) end

--- Decompress data
---@param data string
---@param method? string
---@return string
function core.decompress(data, method) end

--- Serialize table to string
---@param data table
---@return string
function core.serialize(data) end

--- Deserialize string to table
---@param str string
---@return table
function core.deserialize(str) end

--- Add item to inventory or drop as entity
---@param pos vector
---@param item ItemStack|string
---@return ItemStack|nil leftover
function core.add_item(pos, item) end

--- Add entity
---@param pos vector
---@param entity_name string
---@param staticdata? string
---@return ObjectRef|nil
function core.add_entity(pos, entity_name, staticdata) end

--- Check player privileges
---@param player_name string
---@param priv string
---@return boolean
function core.check_player_privs(player_name, priv) end

--- Close formspec
---@param player_name string
---@param formname string
function core.close_formspec(player_name, formname) end

--- Create detached inventory
---@param name string
---@param callbacks table
---@return InvRef|nil
function core.create_detached_inventory(name, callbacks) end

--- Dig node
---@param pos vector
---@param actor? ObjectRef
---@return boolean success
function core.dig_node(pos, actor) end

--- Emerge area
---@param minp vector
---@param maxp vector
---@param callback? fun(blockpos: vector, action: string)
function core.emerge_area(minp, maxp, callback) end

--- Get mapgen setting
---@param name string
---@return any
function core.get_mapgen_setting(name) end

--- Get node level (for leveled nodes)
---@param pos vector
---@return integer
function core.get_node_level(pos) end

--- Set node level
---@param pos vector
---@param level integer
function core.set_node_level(pos, level) end

--- Add to node level
---@param pos vector
---@param add integer
---@return integer new_level
function core.add_node_level(pos, add) end

--- Register alias
---@param name string
---@param convert_to string
function core.register_alias(name, convert_to) end

--- Register on_dignode callback
---@param func fun(pos: vector, oldnode: table, digger: ObjectRef)
function core.register_on_dignode(func) end

--- Register on_punchnode callback
---@param func fun(pos: vector, node: table, puncher: ObjectRef, pointed_thing: table)
function core.register_on_punchnode(func) end

--- Register on_placenode callback
---@param func fun(pos: vector, newnode: table, placer: ObjectRef, oldnode: table, itemstack: ItemStack, pointed_thing: table)
function core.register_on_placenode(func) end

--- Register on_generated callback
---@param func fun(minp: vector, maxp: vector, blockseed: integer)
function core.register_on_generated(func) end

--- Register on_newplayer callback
---@param func fun(player: ObjectRef)
function core.register_on_newplayer(func) end

--- Register on_dieplayer callback
---@param func fun(player: ObjectRef)
function core.register_on_dieplayer(func) end

--- Register on_respawnplayer callback
---@param func fun(player: ObjectRef)
function core.register_on_respawnplayer(func) end

--- Register on_player_hpchange callback
---@param func fun(player: ObjectRef, hp: integer)
function core.register_on_player_hpchange(func) end

--- Register on_player_receive_fields callback
---@param func fun(player: ObjectRef, formname: string, fields: table<string, string>)
function core.register_on_player_receive_fields(func) end

--- Register on_craft callback
---@param func fun(itemstack: ItemStack, player: ObjectRef, old_craft_grid: table, craft_inv: InvRef)
function core.register_on_craft(func) end

--- Register on_craft_predict callback
---@param func fun(itemstack: ItemStack, player: ObjectRef, old_craft_grid: table, craft_inv: InvRef)
function core.register_on_craft_predict(func) end

--- Register on_item_eat callback
---@param func fun(itemstack: ItemStack, player: ObjectRef, old_craft_grid: table, craft_inv: InvRef)
function core.register_on_item_eat(func) end

--- Register craft recipe
---@param definition table
function core.register_craft(definition) end

--- Register ore for mapgen
---@param definition table
function core.register_ore(definition) end

--- Override existing item
---@param name string
---@param definition table
function core.override_item(name, definition) end

--- Get node metadata
---@param pos vector
---@return NodeMetaRef
function core.get_meta(pos) end

--- Get node inventory
---@param pos vector
---@return InvRef
function core.get_inventory(pos) end

-- ==============================
-- Additional functions from official API
-- ==============================

--- Returns a list of mod names (optionally sorted by load order)
---@param load_order? boolean (default false)
---@return string[]
function core.get_modnames(load_order) end

--- Returns a table with information about the current game
---@return {id: string, title: string, author: string, path: string}
function core.get_game_info() end

--- Returns a path for mod-specific data (call during mod load)
---@return string
function core.get_mod_data_path() end

--- Returns true if the server is in singleplayer mode
---@return boolean
function core.is_singleplayer() end

--- Table containing server-side API feature flags
---@type table<string, boolean>
core.features = {}

--- Checks if a feature (or set of features) is available
---@param arg string|table<string, boolean>
---@return boolean, table<string, boolean>|nil
function core.has_feature(arg) end

--- Returns detailed information about a connected player
---@param player_name string
---@return table|nil
function core.get_player_information(player_name) end

--- Table mapping Luanti version strings to protocol version numbers
---@type table<string, integer>
core.protocol_versions = {}

--- Returns information about the player's window (size, scaling, etc.)
---@param player_name string
---@return table|nil
function core.get_player_window_information(player_name) end

--- Checks whether a file system path exists
---@param path string
---@return boolean
function core.path_exists(path) end

--- Removes a directory (optionally recursively)
---@param path string
---@param recursive? boolean
---@return boolean success
function core.rmdir(path, recursive) end

--- Copies a directory recursively
---@param source string
---@param destination string
---@return boolean success
function core.cpdir(source, destination) end

--- Moves a directory
---@param source string
---@param destination string
---@return boolean success
function core.mvdir(source, destination) end