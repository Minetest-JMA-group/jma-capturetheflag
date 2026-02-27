---@meta

--- Luanti (formerly Minetest) Core API
---@class CoreAPI
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
---@param message string
---@param restart boolean
function core.request_shutdown(message, restart) end

--- Get current mod name
---@return string
function core.get_current_modname() end

--- Get player privileges
---@param player_name string
---@return table
function core.get_player_privs(player_name) end

--- Log a message
---@param level string
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
---@return string
function core.get_modpath(modname) end

--- Check if mod is loaded
---@param modname string
---@return boolean
function core.get_mod_storage(modname) end

--- Get server uptime
---@return number
function core.get_us_time() end

--- Get game time
---@return number
function core.get_gametime() end

--- Get server version
---@return string
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
---@param func function
function core.register_on_joinplayer(func) end

--- Register on_leaveplayer callback
---@param func function
function core.register_on_leaveplayer(func) end

--- Register on_chat_message callback
---@param func function
function core.register_on_chat_message(func) end

--- Register globalstep callback
---@param func function
function core.register_globalstep(func) end

--- Get connected players
---@return string[]
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
---@return table
function core.get_node(pos) end

--- Set node at position
---@param pos vector
---@param node table
function core.set_node(pos, node) end

--- Add particle
---@param definition table
function core.add_particle(definition) end

--- Add particle spawner
---@param definition table
function core.add_particlespawner(definition) end

--- Play sound at position
---@param definition table
function core.sound_play(definition) end

--- Registered items table
---@type table<string, table>
core.registered_items = {}

--- Registered nodes table
---@type table<string, table>
core.registered_nodes = {}

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
function core.settings:get_number(name, default) end

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
---@return boolean success
function core.add_item(pos, item) end

--- Add entity
---@param pos vector
---@param entity_name string
---@return ObjectRef|nil
function core.add_entity(pos, entity_name) end

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
---@return boolean success
function core.create_detached_inventory(name, callbacks) end

--- Dig node
---@param pos vector
---@return boolean success
function core.dig_node(pos) end

--- Emerge area
---@param minp vector
---@param maxp vector
---@param callback function
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
function core.add_node_level(pos, level) end

--- Register alias
---@param name string
---@param convert_to string
function core.register_alias(name, convert_to) end

--- Register on_dignode callback
---@param func function
function core.register_on_dignode(func) end

--- Register on_punchnode callback
---@param func function
function core.register_on_punchnode(func) end

--- Register on_placenode callback
---@param func function
function core.register_on_placenode(func) end

--- Register on_generated callback
---@param func function
function core.register_on_generated(func) end

--- Register on_newplayer callback
---@param func function
function core.register_on_newplayer(func) end

--- Register on_dieplayer callback
---@param func function
function core.register_on_dieplayer(func) end

--- Register on_respawnplayer callback
---@param func function
function core.register_on_respawnplayer(func) end

--- Register on_player_hpchange callback
---@param func function
function core.register_on_player_hpchange(func) end

--- Register on_player_receive_fields callback
---@param func function
function core.register_on_player_receive_fields(func) end

--- Register on_craft callback
---@param func function
function core.register_on_craft(func) end

--- Register on_craft_predict callback
---@param func function
function core.register_on_craft_predict(func) end

--- Register on_item_eat callback
---@param func function
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

---@param pos vector
---@return InvRef
function core.get_inventory(pos) end