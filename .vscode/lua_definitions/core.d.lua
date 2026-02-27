---@meta

--- Luanti (formerly Minetest) Core API
---@class CoreAPI
---@field PLAYER_MAX_HP_DEFAULT integer  -- default maximum player hit points (usually 20)
core = {}

--- Get the current world path.
---@return string
function core.get_worldpath() end

--- Create a directory (including parent directories if needed).
---@param path string
---@return boolean success
function core.mkdir(path) end

--- Schedule a function to run after a delay.
---@param delay number Time in seconds (fractional allowed)
---@param func function Function to call
---@param ... any Arguments passed to func
---@return table job Job table with :cancel() method
function core.after(delay, func, ...) end

--- Request server shutdown.
---@param message? string Optional message to display
---@param reconnect? boolean If true, show reconnect button
---@param delay? number Delay in seconds before shutdown (negative cancels pending)
function core.request_shutdown(message, reconnect, delay) end

--- Cancel any pending delayed shutdown.
function core.cancel_shutdown_requests() end

--- Get the name of the currently loading mod.
---@return string
function core.get_current_modname() end

--- Get the directory path of a mod.
---@param modname string
---@return string|nil
function core.get_modpath(modname) end

--- Get a list of mod names.
---@param load_order? boolean If true, sorted by load order (since 5.16.0)
---@return string[]
function core.get_modnames(load_order) end

--- Get information about the current game.
---@return {id: string, title: string, author: string, path: string}
function core.get_game_info() end

--- Get the world directory path.
---@return string
function core.get_worldpath() end

--- Get a path for mod‑specific persistent data (call during mod load).
---@return string
function core.get_mod_data_path() end

--- Check if server is in singleplayer mode.
---@return boolean
function core.is_singleplayer() end

--- Table containing server‑side API feature flags.
---@class CoreFeatures
---@field glasslike_framed? boolean
---@field nodebox_as_selectionbox? boolean
---@field get_all_craft_recipes_works? boolean
---@field use_texture_alpha? boolean
---@field no_legacy_abms? boolean
---@field texture_names_parens? boolean
---@field area_store_custom_ids? boolean
---@field add_entity_with_staticdata? boolean
---@field no_chat_message_prediction? boolean
---@field object_use_texture_alpha? boolean
---@field object_independent_selectionbox? boolean
---@field httpfetch_binary_data? boolean
---@field formspec_version_element? boolean
---@field area_store_persistent_ids? boolean
---@field pathfinder_works? boolean
---@field object_step_has_moveresult? boolean
---@field direct_velocity_on_players? boolean
---@field use_texture_alpha_string_modes? boolean
---@field degrotate_240_steps? boolean
---@field abm_min_max_y? boolean
---@field dynamic_add_media_table? boolean
---@field particlespawner_tweenable? boolean
---@field get_sky_as_table? boolean
---@field get_light_data_buffer? boolean
---@field mod_storage_on_disk? boolean
---@field compress_zstd? boolean
---@field sound_params_start_time? boolean
---@field physics_overrides_v2? boolean
---@field hud_def_type_field? boolean
---@field random_state_restore? boolean
---@field after_order_expiry_registration? boolean
---@field wallmounted_rotate? boolean
---@field item_specific_pointabilities? boolean
---@field blocking_pointability_type? boolean
---@field dynamic_add_media_startup? boolean
---@field dynamic_add_media_filepath? boolean
---@field lsystem_decoration_type? boolean
---@field item_meta_range? boolean
---@field node_interaction_actor? boolean
---@field moveresult_new_pos? boolean
---@field override_item_remove_fields? boolean
---@field hotbar_hud_element? boolean
---@field bulk_lbms? boolean
---@field abm_without_neighbors? boolean
---@field biome_weights? boolean
---@field particle_blend_clip? boolean
---@field remove_item_match_meta? boolean
---@field httpfetch_additional_methods? boolean
---@field object_guids? boolean
---@field on_timer_four_args? boolean
---@field particlespawner_exclude_player? boolean
---@field generate_decorations_biomes? boolean
---@field chunksize_vector? boolean
---@field item_image_animation? boolean
---@field get_modnames_load_order? boolean
core.features = {}

--- Check feature availability.
---@param arg string|table<string, boolean>
---@return boolean available, table<string, boolean> missing
function core.has_feature(arg) end

--- Get information about a connected player.
---@param player_name string
---@return PlayerInfo|nil
function core.get_player_information(player_name) end

---@class PlayerInfo
---@field address string
---@field ip_version integer
---@field connection_uptime number
---@field protocol_version integer
---@field formspec_version integer
---@field lang_code string
---@field min_rtt? number
---@field max_rtt? number
---@field avg_rtt? number
---@field min_jitter? number
---@field max_jitter? number
---@field avg_jitter? number
---@field version_string string

--- Table mapping Luanti version strings to protocol version numbers.
---@type table<string, integer>
core.protocol_versions = {}

--- Get window information for a player.
---@param player_name string
---@return PlayerWindowInfo|nil
function core.get_player_window_information(player_name) end

---@class PlayerWindowInfo
---@field size {x: integer, y: integer}
---@field max_formspec_size {x: number, y: number}
---@field real_gui_scaling number
---@field real_hud_scaling number
---@field touch_controls boolean

--- Check if a filesystem path exists.
---@param path string
---@return boolean
function core.path_exists(path) end

--- Remove a directory.
---@param path string
---@param recursive? boolean If true, remove recursively
---@return boolean success
function core.rmdir(path, recursive) end

--- Copy a directory recursively.
---@param source string
---@param destination string
---@return boolean success
function core.cpdir(source, destination) end

--- Move a directory.
---@param source string
---@param destination string
---@return boolean success
function core.mvdir(source, destination) end

--- List directory contents.
---@param path string
---@param is_dir? nil|boolean If true, return only subdirectories; if false, only files; if nil, all
---@return string[] entry_names
function core.get_dir_list(path, is_dir) end

--- Atomically write a file.
---@param path string
---@param content string
---@return boolean success
function core.safe_file_write(path, content) end

--- Get engine version information.
---@return {project: string, string: string, proto_min: integer, proto_max: integer, hash?: string, is_dev: boolean}
function core.get_version() end

--- Compute SHA‑1 hash.
---@param data string
---@param raw? boolean If true, return raw bytes (default false)
---@return string
function core.sha1(data, raw) end

--- Compute SHA‑256 hash.
---@param data string
---@param raw? boolean If true, return raw bytes (default false)
---@return string
function core.sha256(data, raw) end

--- Convert ColorSpec to ColorString.
---@param colorspec table|integer|string
---@return string|nil
function core.colorspec_to_colorstring(colorspec) end

--- Convert ColorSpec to raw RGBA bytes.
---@param colorspec table|integer|string
---@return string (4 bytes)
function core.colorspec_to_bytes(colorspec) end

--- Convert ColorSpec to RGBA table.
---@param colorspec table|integer|string
---@return {r:integer, g:integer, b:integer, a:integer}|nil
function core.colorspec_to_table(colorspec) end

--- Convert time of day to day‑night ratio.
---@param time_of_day number (0‑1)
---@return number ratio (0‑1)
function core.time_to_day_night_ratio(time_of_day) end

--- Encode raw pixel data as PNG.
---@param width integer
---@param height integer
---@param data table|string ColorSpec array or raw RGBA string
---@param compression? integer 0‑9 (zlib level)
---@return string PNG data
function core.encode_png(width, height, data, compression) end

--- URL‑encode a string.
---@param str string
---@return string
function core.urlencode(str) end

--- Log a message.
---@param level "error"|"warning"|"action"|"info"|"verbose"|"none"
---@param message string
function core.log(level, message) end

--- Equivalent to core.log with all arguments converted to string and tab‑separated.
---@param ... any
function core.debug(...) end

--- Get player privileges.
---@param player_name string
---@return table<string, boolean>
function core.get_player_privs(player_name) end

--- Convert privilege string to table.
---@param str string
---@param delim? string (default ",")
---@return table<string, boolean>
function core.string_to_privs(str, delim) end

--- Convert privilege table to string.
---@param privs table<string, boolean>
---@param delim? string (default ",")
---@return string
function core.privs_to_string(privs, delim) end

--- Check player privileges.
---@param player_or_name string|ObjectRef
---@param ... string|table<string,boolean> List of privs or table
---@return boolean has_all, table<string,boolean> missing
function core.check_player_privs(player_or_name, ...) end

--- Check a password entry.
---@param name string
---@param entry string Password hash from auth database
---@param password string Plaintext password to check
---@return boolean matches
function core.check_password_entry(name, entry, password) end

--- Get password hash (old‑style).
---@param name string
---@param raw_password string
---@return string hash
function core.get_password_hash(name, raw_password) end

--- Get IP address of an online player.
---@param name string
---@return string|nil
function core.get_player_ip(name) end

--- Get the current authentication handler.
---@return AuthHandler
function core.get_auth_handler() end

--- Notify the engine that authentication data has been modified.
---@param name? string If omitted, all data may be modified
function core.notify_authentication_modified(name) end

--- Set a player's password hash.
---@param name string
---@param password_hash string
function core.set_player_password(name, password_hash) end

--- Set a player's privileges (replaces all).
---@param name string
---@param privs table<string, boolean>
function core.set_player_privs(name, privs) end

--- Grant or revoke privileges.
---@param name string
---@param changes table<string, boolean> true to grant, false to revoke
function core.change_player_privs(name, changes) end

--- Reload authentication data from storage.
---@return boolean success
function core.auth_reload() end

--- Send a chat message to all players.
---@param message string
function core.chat_send_all(message) end

--- Send a chat message to a specific player.
---@param player_name string
---@param message string
function core.chat_send_player(player_name, message) end

--- Format a chat message according to server settings.
---@param name string Player name
---@param message string
---@return string formatted
function core.format_chat_message(name, message) end

--- Show a formspec to a player.
---@param player_name string
---@param formname string
---@param formspec string
function core.show_formspec(player_name, formname, formspec) end

--- Close a formspec for a player.
---@param player_name string
---@param formname string Use "" to close any formspec
function core.close_formspec(player_name, formname) end

--- Escape a string for use in formspecs.
---@param str string
---@return string
function core.formspec_escape(str) end

--- Escape a string for use in hypertext.
---@param str string
---@return string
function core.hypertext_escape(str) end

--- Parse a table event from formspec.
---@param event string
---@return {type:"INV"|"CHG"|"DCL", row?:integer, column?:integer}
function core.explode_table_event(event) end

--- Parse a textlist event.
---@param event string
---@return {type:"INV"|"CHG"|"DCL", index?:integer}
function core.explode_textlist_event(event) end

--- Parse a scrollbar event.
---@param event string
---@return {type:"INV"|"CHG"|"VAL", value?:integer}
function core.explode_scrollbar_event(event) end

--- Show the death screen for a player.
---@param player ObjectRef
---@param reason? PlayerHPChangeReason
function core.show_death_screen(player, reason) end

--- Register a node.
---@param name string
---@param definition table Node definition
function core.register_node(name, definition) end

--- Register a tool.
---@param name string
---@param definition table Tool definition
function core.register_tool(name, definition) end

--- Register a craftitem.
---@param name string
---@param definition table Craftitem definition
function core.register_craftitem(name, definition) end

--- Register an entity.
---@param name string
---@param definition table Entity definition
function core.register_entity(name, definition) end

--- Register an ABM (Active Block Modifier).
---@param definition table ABM definition
function core.register_abm(definition) end

--- Register an LBM (Loading Block Modifier).
---@param definition table LBM definition
function core.register_lbm(definition) end

--- Override an existing item definition.
---@param name string
---@param redefinition table
---@param del_fields? string[] List of field names to delete
function core.override_item(name, redefinition, del_fields) end

--- Unregister an item.
---@param name string
function core.unregister_item(name) end

--- Register an alias.
---@param alias string
---@param original_name string
function core.register_alias(alias, original_name) end

--- Register an alias forcefully (overwrites existing).
---@param alias string
---@param original_name string
function core.register_alias_force(alias, original_name) end

--- Register an ore.
---@param definition table Ore definition
---@return integer handle
function core.register_ore(definition) end

--- Register a biome.
---@param definition table Biome definition
---@return integer handle
function core.register_biome(definition) end

--- Unregister a biome.
---@param name string
function core.unregister_biome(name) end

--- Register a decoration.
---@param definition table Decoration definition
---@return integer handle
function core.register_decoration(definition) end

--- Register a schematic.
---@param definition table Schematic definition
---@return integer handle
function core.register_schematic(definition) end

--- Clear all registered biomes.
function core.clear_registered_biomes() end

--- Clear all registered decorations.
function core.clear_registered_decorations() end

--- Clear all registered ores.
function core.clear_registered_ores() end

--- Clear all registered schematics.
function core.clear_registered_schematics() end

--- Register a craft recipe.
---@param recipe table
function core.register_craft(recipe) end

--- Clear a craft recipe.
---@param recipe table Either {output = item} or full recipe input
---@return boolean success
function core.clear_craft(recipe) end

--- Register a chat command.
---@param name string
---@param definition table ChatCommand definition
function core.register_chatcommand(name, definition) end

--- Override a chat command.
---@param name string
---@param redefinition table
function core.override_chatcommand(name, redefinition) end

--- Unregister a chat command.
---@param name string
function core.unregister_chatcommand(name) end

--- Register a privilege.
---@param name string
---@param definition string|PrivilegeDef Description or definition table
function core.register_privilege(name, definition) end

---@class PrivilegeDef
---@field description string
---@field give_to_singleplayer? boolean
---@field give_to_admin? boolean
---@field on_grant? fun(name:string, granter_name:string|nil)
---@field on_revoke? fun(name:string, revoker_name:string|nil)

--- Register an authentication handler.
---@param definition AuthHandler
function core.register_authentication_handler(definition) end

---@class AuthHandler
---@field get_auth fun(name:string): {password:string, privileges:table<string,boolean>, last_login?:number}|nil
---@field create_auth fun(name:string, password:string)
---@field delete_auth fun(name:string): boolean
---@field set_password fun(name:string, password:string)
---@field set_privileges fun(name:string, privileges:table<string,boolean>)
---@field reload fun(): boolean
---@field record_login fun(name:string)
---@field iterate fun(): function

-- Global callbacks

--- Register a global step callback.
---@param func fun(dtime: number)
function core.register_globalstep(func) end

--- Register a callback after all mods are loaded.
---@param func fun()
function core.register_on_mods_loaded(func) end

--- Register a shutdown callback.
---@param func fun()
function core.register_on_shutdown(func) end

--- Register a callback when a node is placed.
---@param func fun(pos: vector, newnode: table, placer: ObjectRef|nil, oldnode: table, itemstack: ItemStack, pointed_thing: table)
function core.register_on_placenode(func) end

--- Register a callback when a node is dug.
---@param func fun(pos: vector, oldnode: table, digger: ObjectRef|nil)
function core.register_on_dignode(func) end

--- Register a callback when a node is punched.
---@param func fun(pos: vector, node: table, puncher: ObjectRef, pointed_thing: table)
function core.register_on_punchnode(func) end

--- Register a callback when a mapchunk is generated.
---@param func fun(minp: vector, maxp: vector, blockseed: integer)
function core.register_on_generated(func) end

--- Register a callback when a new player joins for the first time.
---@param func fun(player: ObjectRef)
function core.register_on_newplayer(func) end

--- Register a callback when a player joins.
---@param func fun(player: ObjectRef, last_login: number|nil)
function core.register_on_joinplayer(func) end

--- Register a callback when a player leaves.
---@param func fun(player: ObjectRef, timed_out: boolean)
function core.register_on_leaveplayer(func) end

--- Register a callback when a player dies.
---@param func fun(player: ObjectRef, reason: PlayerHPChangeReason)
function core.register_on_dieplayer(func) end

--- Register a callback when a player respawns.
---@param func fun(player: ObjectRef): boolean|nil Return true to cancel default placement
function core.register_on_respawnplayer(func) end

--- Register a callback when a player's HP changes.
---@param func fun(player: ObjectRef, hp_change: integer, reason: PlayerHPChangeReason): (integer|nil, boolean|nil) If modifier, return new hp_change and optionally true to stop further modifiers
---@param modifier? boolean If true, function can modify the change
function core.register_on_player_hpchange(func, modifier) end

---@class PlayerHPChangeReason
---@field type "set_hp"|"punch"|"fall"|"node_damage"|"drown"|"respawn"
---@field custom_type? string
---@field from "engine"|"mod"
---@field object? ObjectRef
---@field node? string
---@field node_pos? vector

--- Register a callback when a player punches another player.
---@param func fun(player: ObjectRef, hitter: ObjectRef|nil, time_from_last_punch: number|nil, tool_capabilities: table|nil, dir: vector, damage: number): boolean|nil Return true to cancel default damage
function core.register_on_punchplayer(func) end

--- Register a callback when a player right‑clicks another player.
---@param func fun(player: ObjectRef, clicker: ObjectRef)
function core.register_on_rightclickplayer(func) end

--- Register a callback when a player sends chat message.
---@param func fun(name: string, message: string): boolean|nil Return true to mark as handled (not sent to others)
function core.register_on_chat_message(func) end

--- Register a callback when a chat command is executed.
---@param func fun(name: string, command: string, params: string): boolean|nil Return true to prevent default handling
function core.register_on_chatcommand(func) end

--- Register a callback when a player sends formspec fields.
---@param func fun(player: ObjectRef, formname: string, fields: table<string, string>): boolean|nil Return true to stop other callbacks
function core.register_on_player_receive_fields(func) end

--- Register a callback when a player crafts something.
---@param func fun(itemstack: ItemStack, player: ObjectRef, old_craft_grid: ItemStack[], craft_inv: InvRef): ItemStack|nil Return replacement output or nil
function core.register_on_craft(func) end

--- Register a callback for craft prediction.
---@param func fun(itemstack: ItemStack, player: ObjectRef, old_craft_grid: ItemStack[], craft_inv: InvRef)
function core.register_on_craft_predict(func) end

--- Register a callback when an item is eaten.
---@param func fun(hp_change: integer, replace_with_item: string|nil, itemstack: ItemStack, user: ObjectRef, pointed_thing: table): ItemStack|nil Return leftover stack to cancel default
function core.register_on_item_eat(func) end

--- Register a callback when an item is picked up.
---@param func fun(itemstack: ItemStack, picker: ObjectRef, pointed_thing: table, time_from_last_punch?: number, ...): ItemStack|nil Return leftover stack to cancel default
function core.register_on_item_pickup(func) end

--- Register a callback to allow/disallow player inventory actions.
---@param func fun(player: ObjectRef, action: string, inventory: InvRef, info: table): integer Return number of items allowed (-1 for infinite)
function core.register_allow_player_inventory_action(func) end

--- Register a callback after a player inventory action.
---@param func fun(player: ObjectRef, action: string, inventory: InvRef, info: table)
function core.register_on_player_inventory_action(func) end

--- Register a callback on protection violation.
---@param func fun(pos: vector, name: string)
function core.register_on_protection_violation(func) end

--- Register a callback when a privilege is granted.
---@param func fun(name: string, granter: string|nil, priv: string): boolean|nil Return true to stop other callbacks
function core.register_on_priv_grant(func) end

--- Register a callback when a privilege is revoked.
---@param func fun(name: string, revoker: string|nil, priv: string): boolean|nil Return true to stop other callbacks
function core.register_on_priv_revoke(func) end

--- Register a callback to bypass user limit.
---@param func fun(name: string, ip: string): boolean Return true to allow join despite limit
function core.register_can_bypass_userlimit(func) end

--- Register a callback for mod channel messages.
---@param func fun(channel: string, sender: string, message: string)
function core.register_on_modchannel_message(func) end

--- Register a callback when liquid transforms.
---@param func fun(pos_list: vector[], node_list: table[])
function core.register_on_liquid_transformed(func) end

--- Register a callback when mapblocks change.
---@param func fun(modified_blocks: table<integer,true>, modified_block_count: integer)
function core.register_on_mapblocks_changed(func) end

--- Register a callback when a player attempts to join (pre‑auth).
---@param func fun(name: string, ip: string): string|nil Return string to disconnect with that reason
function core.register_on_prejoinplayer(func) end

--- Register a callback on authentication attempt.
---@param func fun(name: string, ip: string, is_success: boolean)
function core.register_on_authplayer(func) end

--- Register a callback on cheat detection.
---@param func fun(player: ObjectRef, cheat: {type: string})
function core.register_on_cheat(func) end

--- Get connected players.
---@return ObjectRef[]
function core.get_connected_players() end

--- Get a player by name.
---@param name string
---@return ObjectRef|nil
function core.get_player_by_name(name) end

--- Check if a player exists (offline or online).
---@param name string
---@return boolean
function core.player_exists(name) end

--- Check if a name could be used as a valid player name.
---@param name string
---@return boolean
function core.is_valid_player_name(name) end

--- Check if an object is a player.
---@param obj ObjectRef
---@return boolean
function core.is_player(obj) end

--- Get node at position.
---@param pos vector
---@return {name: string, param1: integer, param2: integer}
function core.get_node(pos) end

--- Get node or nil if area not loaded.
---@param pos vector
---@return {name: string, param1: integer, param2: integer}|nil
function core.get_node_or_nil(pos) end

--- Low‑level get node.
---@param x integer
---@param y integer
---@param z integer
---@return integer content_id, integer param1, integer param2, boolean pos_ok
function core.get_node_raw(x, y, z) end

--- Set node at position.
---@param pos vector
---@param node {name: string, param1?: integer, param2?: integer}
function core.set_node(pos, node) end

--- Alias for set_node.
---@param pos vector
---@param node table
function core.add_node(pos, node) end

--- Set the same node at multiple positions.
---@param positions vector[]
---@param node {name: string, param1?: integer, param2?: integer}
function core.bulk_set_node(positions, node) end

--- Swap node (keeps metadata, no callbacks).
---@param pos vector
---@param node {name: string, param1?: integer, param2?: integer}
function core.swap_node(pos, node) end

--- Bulk swap nodes.
---@param positions vector[]
---@param node {name: string, param1?: integer, param2?: integer}
function core.bulk_swap_node(positions, node) end

--- Remove node (set to air).
---@param pos vector
function core.remove_node(pos) end

--- Get light at position.
---@param pos vector
---@param timeofday? number 0‑1, nil for current
---@return integer|nil 0‑15
function core.get_node_light(pos, timeofday) end

--- Get natural light (sun/moon) at position.
---@param pos vector
---@param timeofday? number 0‑1, nil for current
---@return integer|nil 0‑15
function core.get_natural_light(pos, timeofday) end

--- Get artificial light from param1.
---@param param1 integer
---@return integer 0‑15
function core.get_artificial_light(param1) end

--- Place a node as if by a player.
---@param pos vector
---@param node {name: string, param1?: integer, param2?: integer}
---@param placer? ObjectRef
function core.place_node(pos, node, placer) end

--- Dig a node as if by a player.
---@param pos vector
---@param digger? ObjectRef
---@return boolean success
function core.dig_node(pos, digger) end

--- Punch a node.
---@param pos vector
---@param puncher? ObjectRef
function core.punch_node(pos, puncher) end

--- Turn a node into a falling node entity.
---@param pos vector
---@return boolean success, ObjectRef|nil entity
function core.spawn_falling_node(pos) end

--- Find positions of nodes with metadata in a region.
---@param pos1 vector
---@param pos2 vector
---@return vector[]
function core.find_nodes_with_meta(pos1, pos2) end

--- Get node metadata.
---@param pos vector
---@return NodeMetaRef
function core.get_meta(pos) end

--- Get node timer.
---@param pos vector
---@return NodeTimerRef
function core.get_node_timer(pos) end

--- Add an entity.
---@param pos vector
---@param name string Entity name
---@param staticdata? string
---@return ObjectRef|nil
function core.add_entity(pos, name, staticdata) end

--- Add an item entity.
---@param pos vector
---@param item ItemStack|string
---@return ObjectRef|nil
function core.add_item(pos, item) end

--- Get all objects inside a radius.
---@param center vector
---@param radius number
---@return ObjectRef[]
function core.get_objects_inside_radius(center, radius) end

--- Iterate over valid objects inside a radius.
---@param center vector
---@param radius number
---@return fun(): ObjectRef|nil
function core.objects_inside_radius(center, radius) end

--- Get all objects in an axis‑aligned area.
---@param min_pos vector
---@param max_pos vector
---@return ObjectRef[]
function core.get_objects_in_area(min_pos, max_pos) end

--- Iterate over valid objects in an area.
---@param min_pos vector
---@param max_pos vector
---@return fun(): ObjectRef|nil
function core.objects_in_area(min_pos, max_pos) end

--- Set time of day.
---@param val number 0‑1
function core.set_timeofday(val) end

--- Get time of day.
---@return number 0‑1
function core.get_timeofday() end

--- Get game time (seconds since world creation).
---@return number|nil
function core.get_gametime() end

--- Get number of days elapsed.
---@return integer
function core.get_day_count() end

--- Find a node near a position.
---@param pos vector
---@param radius number (maximum metric)
---@param nodenames string|string[]
---@param search_center? boolean (default false)
---@return vector|nil
function core.find_node_near(pos, radius, nodenames, search_center) end

--- Find nodes in an area.
---@param pos1 vector
---@param pos2 vector
---@param nodenames string|string[]
---@param grouped? boolean If true, return table indexed by node name
---@return vector[]|table<string,vector[]> positions, table<string,integer>? counts
function core.find_nodes_in_area(pos1, pos2, nodenames, grouped) end

--- Find nodes in an area that have air above.
---@param pos1 vector
---@param pos2 vector
---@param nodenames string|string[]
---@return vector[]
function core.find_nodes_in_area_under_air(pos1, pos2, nodenames) end

--- Get a value noise instance (world‑specific).
---@param noiseparams table NoiseParams
---@return ValueNoise
function core.get_value_noise(noiseparams) end

--- Deprecated, use get_value_noise.
---@param seeddiff integer
---@param octaves integer
---@param persistence number
---@param spread number|vector
---@return ValueNoise
function core.get_perlin(seeddiff, octaves, persistence, spread) end

--- Get a voxel manipulator.
---@param pos1? vector
---@param pos2? vector
---@return VoxelManip
function core.get_voxel_manip(pos1, pos2) end

--- Set gennotify flags.
---@param flags string
---@param deco_ids? integer[]
---@param custom_ids? string[]
function core.set_gen_notify(flags, deco_ids, custom_ids) end

--- Get gennotify settings.
---@return string flags, integer[] deco_ids, string[] custom_ids
function core.get_gen_notify() end

--- Get decoration ID by name.
---@param name string
---@return integer|nil
function core.get_decoration_id(name) end

--- Get a mapgen object.
---@param objectname "voxelmanip"|"heightmap"|"biomemap"|"heatmap"|"humiditymap"|"gennotify"
---@return any ... Varies by object
function core.get_mapgen_object(objectname) end

--- Get heat at a position.
---@param pos vector
---@return number|nil
function core.get_heat(pos) end

--- Get humidity at a position.
---@param pos vector
---@return number|nil
function core.get_humidity(pos) end

--- Get biome data at a position.
---@param pos vector
---@return {biome: integer, heat: number, humidity: number}|nil
function core.get_biome_data(pos) end

--- Get biome ID by name.
---@param name string
---@return integer|nil
function core.get_biome_id(name) end

--- Get biome name by ID.
---@param id integer
---@return string|nil
function core.get_biome_name(id) end

--- Deprecated: use get_mapgen_setting.
---@return {mgname:string, seed:integer, chunksize:integer, water_level:integer, flags:string}
function core.get_mapgen_params() end

--- Deprecated: use set_mapgen_setting.
---@param params table
function core.set_mapgen_params(params) end

--- Get the minimum and maximum generated node positions.
---@param mapgen_limit? integer
---@param chunksize? integer|vector
---@return vector minp, vector maxp
function core.get_mapgen_edges(mapgen_limit, chunksize) end

--- Get the mapgen chunksize (in blocks).
---@return vector
function core.get_mapgen_chunksize() end

--- Get an active mapgen setting.
---@param name string
---@return string|nil
function core.get_mapgen_setting(name) end

--- Get a mapgen setting as NoiseParams.
---@param name string
---@return table|nil
function core.get_mapgen_setting_noiseparams(name) end

--- Set a mapgen setting.
---@param name string
---@param value string
---@param override_meta? boolean (default false)
function core.set_mapgen_setting(name, value, override_meta) end

--- Set a mapgen setting as NoiseParams.
---@param name string
---@param value table
---@param override_meta? boolean (default false)
function core.set_mapgen_setting_noiseparams(name, value, override_meta) end

--- Set a noiseparams setting.
---@param name string
---@param noiseparams table
---@param set_default? boolean (default true)
function core.set_noiseparams(name, noiseparams, set_default) end

--- Get a noiseparams setting.
---@param name string
---@return table|nil
function core.get_noiseparams(name) end

--- Generate ores inside a VoxelManip.
---@param vm VoxelManip
---@param pos1? vector
---@param pos2? vector
function core.generate_ores(vm, pos1, pos2) end

--- Generate decorations inside a VoxelManip.
---@param vm VoxelManip
---@param pos1? vector
---@param pos2? vector
---@param use_mapgen_biomes? boolean (default false)
function core.generate_decorations(vm, pos1, pos2, use_mapgen_biomes) end

--- Clear objects in the environment.
---@param options? {mode:"full"|"quick"} Default full
function core.clear_objects(options) end

--- Load mapblocks containing an area.
---@param pos1 vector
---@param pos2? vector (default pos1)
function core.load_area(pos1, pos2) end

--- Queue area for emergence (asynchronous).
---@param pos1 vector
---@param pos2 vector
---@param callback? fun(blockpos:vector, action:integer, calls_remaining:integer, param:any)
---@param param? any User data passed to callback
function core.emerge_area(pos1, pos2, callback, param) end

--- Delete mapblocks in an area.
---@param pos1 vector
---@param pos2 vector
function core.delete_area(pos1, pos2) end

--- Check line of sight between two positions.
---@param pos1 vector
---@param pos2 vector
---@return boolean has_line_of_sight, vector|nil blocking_pos
function core.line_of_sight(pos1, pos2) end

--- Create a raycast.
---@param pos1 vector
---@param pos2 vector
---@param objects? boolean (default true)
---@param liquids? boolean (default false)
---@param pointabilities? table Override pointable properties
---@return Raycast
function core.raycast(pos1, pos2, objects, liquids, pointabilities) end

--- Find a walkable path between two positions.
---@param pos1 vector
---@param pos2 vector
---@param searchdistance number
---@param max_jump number
---@param max_drop number
---@param algorithm? "A*_noprefetch"|"A*"|"Dijkstra" (default "A*_noprefetch")
---@return vector[]|nil path
function core.find_path(pos1, pos2, searchdistance, max_jump, max_drop, algorithm) end

--- Spawn an L‑system tree.
---@param pos vector
---@param treedef table
function core.spawn_tree(pos, treedef) end

--- Spawn an L‑system tree onto a VoxelManip.
---@param vmanip VoxelManip
---@param pos vector
---@param treedef table
function core.spawn_tree_on_vmanip(vmanip, pos, treedef) end

--- Add a node to the liquid flow update queue.
---@param pos vector
function core.transforming_liquid_add(pos) end

--- Get maximum level for a leveled node.
---@param pos vector
---@return integer max
function core.get_node_max_level(pos) end

--- Get current level of a leveled node.
---@param pos vector
---@return integer level
function core.get_node_level(pos) end

--- Set level of a leveled node.
---@param pos vector
---@param level integer
function core.set_node_level(pos, level) end

--- Add to level of a leveled node.
---@param pos vector
---@param add integer
---@return integer new_level
function core.add_node_level(pos, add) end

--- Get actual node boxes after applying rotation etc.
---@param box_type "node_box"|"collision_box"|"selection_box"
---@param pos vector
---@param node? table Node table (uses actual node if nil)
---@return {[1]:number, [2]:number, [3]:number, [4]:number, [5]:number, [6]:number}[]
function core.get_node_boxes(box_type, pos, node) end

--- Fix lighting in an area.
---@param pos1 vector
---@param pos2 vector
---@return boolean success (false if area not fully generated)
function core.fix_light(pos1, pos2) end

--- Cause a single falling node to fall if unsupported.
---@param pos vector
function core.check_single_for_falling(pos) end

--- Cause falling nodes to fall and propagate.
---@param pos vector
function core.check_for_falling(pos) end

--- Get spawn Y coordinate at (x,z).
---@param x integer
---@param z integer
---@return integer|nil y
function core.get_spawn_level(x, z) end

--- Join a mod channel.
---@param channel_name string
---@return ModChannel
function core.mod_channel_join(channel_name) end

--- Get an inventory reference.
---@param location {type:"player", name:string}|{type:"node", pos:vector}|{type:"detached", name:string}
---@return InvRef
function core.get_inventory(location) end

--- Create a detached inventory.
---@param name string
---@param callbacks DetachedInventoryCallbacks
---@param player_name? string If given, inventory is sent only to that player
---@return InvRef
function core.create_detached_inventory(name, callbacks, player_name) end

--- Remove a detached inventory.
---@param name string
---@return boolean success
function core.remove_detached_inventory(name) end

--- Execute an item eat action.
---@param hp_change integer
---@param replace_with_item string|nil
---@param itemstack ItemStack
---@param user ObjectRef
---@param pointed_thing table
---@return ItemStack|nil leftover (nil = no change)
function core.do_item_eat(hp_change, replace_with_item, itemstack, user, pointed_thing) end

--- Utility to create an eat function.
---@param hp_change integer
---@param replace_with_item? string
---@return fun(itemstack:ItemStack, user:ObjectRef, pointed_thing:table): ItemStack|nil
function core.item_eat(hp_change, replace_with_item) end

--- Default node placement function.
---@param itemstack ItemStack
---@param placer ObjectRef|nil
---@param pointed_thing table
---@param param2? integer Override param2
---@param prevent_after_place? boolean
---@return ItemStack, vector|nil placed_pos
function core.item_place_node(itemstack, placer, pointed_thing, param2, prevent_after_place) end

--- Deprecated: use item_place.
function core.item_place_object(itemstack, placer, pointed_thing) end

--- Default item placement dispatcher.
---@param itemstack ItemStack
---@param placer ObjectRef|nil
---@param pointed_thing table
---@param param2? integer
---@return ItemStack, vector|nil placed_pos
function core.item_place(itemstack, placer, pointed_thing, param2) end

--- Default item pickup handler.
---@param itemstack ItemStack
---@param picker ObjectRef
---@param pointed_thing table
---@param time_from_last_punch? number
---@param ... any
---@return ItemStack leftover
function core.item_pickup(itemstack, picker, pointed_thing, time_from_last_punch, ...) end

--- Default secondary use (does nothing).
---@param itemstack ItemStack
---@param user ObjectRef
---@param pointed_thing table
---@return ItemStack|nil
function core.item_secondary_use(itemstack, user, pointed_thing) end

--- Default drop function.
---@param itemstack ItemStack
---@param dropper ObjectRef|nil
---@param pos vector
---@return ItemStack leftover, ObjectRef|nil entity
function core.item_drop(itemstack, dropper, pos) end

--- Default node punch callback.
---@param pos vector
---@param node table
---@param puncher ObjectRef
---@param pointed_thing table
function core.node_punch(pos, node, puncher, pointed_thing) end

--- Default node dig callback.
---@param pos vector
---@param node table
---@param digger ObjectRef
function core.node_dig(pos, node, digger) end

--- Play a sound.
---@param spec SimpleSoundSpec
---@param parameters SoundParams
---@param ephemeral? boolean (default false)
---@return integer|nil handle
function core.sound_play(spec, parameters, ephemeral) end

--- Stop a sound.
---@param handle integer
function core.sound_stop(handle) end

--- Fade a sound.
---@param handle integer
---@param step number Gain change per second
---@param gain number Target gain
function core.sound_fade(handle, step, gain) end

---@alias SimpleSoundSpec string|{name:string, gain?:number, pitch?:number, fade?:number}
---@class SoundParams
---@field gain? number
---@field pitch? number
---@field fade? number
---@field start_time? number
---@field loop? boolean
---@field pos? vector
---@field object? ObjectRef
---@field to_player? string
---@field exclude_player? string
---@field max_hear_distance? number

--- Queue an async job.
---@param func function Function to run in async environment
---@param callback function Callback with results
---@param ... any Arguments passed to func
---@return AsyncJob
function core.handle_async(func, callback, ...) end

--- Register a file to be loaded in each async environment.
---@param path string
function core.register_async_dofile(path) end

--- Register a file to be loaded in each mapgen environment.
---@param path string
function core.register_mapgen_script(path) end

--- Save gennotify data (mapgen environment only).
---@param id string
---@param data any
---@return boolean success
function core.save_gen_notify(id, data) end

--- Get server status string.
---@param name string Player name
---@param joined boolean Called on join?
---@return string|nil
function core.get_server_status(name, joined) end

--- Get server uptime in seconds.
---@return number
function core.get_server_uptime() end

--- Get current maximum server lag.
---@return number|nil
function core.get_server_max_lag() end

--- Remove a player from the database (if not connected).
---@param name string
---@return integer 0=success,1=no such player,2=player connected
function core.remove_player(name) end

--- Remove player authentication data.
---@param name string
---@return boolean success
function core.remove_player_auth(name) end

--- Dynamically add media to clients.
---@param options {filename?:string, filepath?:string, filedata?:string, to_player?:string, ephemeral?:boolean, client_cache?:boolean}
---@param callback? fun(name:string)
---@return boolean accepted
function core.dynamic_add_media(options, callback) end

--- IPC: get a value.
---@param key string
---@return any
function core.ipc_get(key) end

--- IPC: set a value.
---@param key string
---@param value any
function core.ipc_set(key, value) end

--- IPC: compare‑and‑swap.
---@param key string
---@param old_value any
---@param new_value any
---@return boolean success
function core.ipc_cas(key, old_value, new_value) end

--- IPC: poll for a key (blocking).
---@param key string
---@param timeout integer Milliseconds
---@return boolean success (false on timeout)
function core.ipc_poll(key, timeout) end

--- Get ban list as string.
---@return string
function core.get_ban_list() end

--- Get ban description for an IP or name.
---@param ip_or_name string
---@return string
function core.get_ban_description(ip_or_name) end

--- Ban a currently connected player.
---@param name string
---@return boolean success
function core.ban_player(name) end

--- Unban an IP or name.
---@param ip_or_name string
---@return boolean success
function core.unban_player_or_ip(ip_or_name) end

--- Kick a player.
---@param name string
---@param reason? string
---@param reconnect? boolean
---@return boolean success
function core.kick_player(name, reason, reconnect) end

--- Disconnect a player (without "Kicked:" prefix).
---@param name string
---@param reason? string (default "Disconnected.")
---@param reconnect? boolean
---@return boolean success
function core.disconnect_player(name, reason, reconnect) end

--- Add a single particle.
---@param def table Particle definition
function core.add_particle(def) end

--- Add a particle spawner.
---@param def table ParticleSpawner definition
---@return integer id (or -1 on failure)
function core.add_particlespawner(def) end

--- Delete a particle spawner.
---@param id integer
---@param player? string If given, delete only on that player's client
function core.delete_particlespawner(id, player) end

--- Create a schematic from a region.
---@param p1 vector
---@param p2 vector
---@param probability_list? {pos:vector, prob:integer}[]
---@param filename string
---@param slice_prob_list? {ypos:integer, prob:integer}[]
function core.create_schematic(p1, p2, probability_list, filename, slice_prob_list) end

--- Place a schematic.
---@param pos vector
---@param schematic string|table
---@param rotation? "0"|"90"|"180"|"270"|"random"
---@param replacements? table<string,string>
---@param force_placement? boolean
---@param flags? string
---@return boolean|nil success (nil if cannot load)
function core.place_schematic(pos, schematic, rotation, replacements, force_placement, flags) end

--- Place a schematic onto a VoxelManip.
---@param vmanip VoxelManip
---@param pos vector
---@param schematic string|table
---@param rotation? string
---@param replacements? table
---@param force_placement? boolean
---@param flags? string
---@return boolean|nil fits (nil if cannot load)
function core.place_schematic_on_vmanip(vmanip, pos, schematic, rotation, replacements, force_placement, flags) end

--- Serialize a schematic to a string.
---@param schematic string|table
---@param format "mts"|"lua"
---@param options? {lua_use_comments?:boolean, lua_num_indent_spaces?:integer}
---@return string|nil
function core.serialize_schematic(schematic, format, options) end

--- Read a schematic into a table.
---@param schematic string|table
---@param options? {write_yslice_prob?:"none"|"low"|"all"}
---@return table|nil
function core.read_schematic(schematic, options) end

--- Request HTTP API table (if mod is trusted).
---@return HTTPApiTable|nil
function core.request_http_api() end

---@class HTTPApiTable
---@field fetch fun(req:HTTPRequest, callback:fun(res:HTTPRequestResult))
---@field fetch_async fun(req:HTTPRequest): integer
---@field fetch_async_get fun(handle:integer): HTTPRequestResult

---@class HTTPRequest
---@field url string
---@field timeout? integer
---@field method? "GET"|"HEAD"|"POST"|"PUT"|"PATCH"|"DELETE"
---@field data? string|table
---@field user_agent? string
---@field extra_headers? string[]
---@field multipart? boolean

---@class HTTPRequestResult
---@field completed boolean
---@field succeeded boolean
---@field timeout boolean
---@field code integer
---@field data string

--- Get mod storage.
---@param modname string
---@return ModStorage
function core.get_mod_storage(modname) end

--- Replace a built‑in HUD element.
---@param name "breath"|"health"|"minimap"|"hotbar"
---@param def table HUD definition
function core.hud_replace_builtin(name, def) end

--- Parse a relative number (tilde notation).
---@param arg string
---@param relative_to number
---@return number|nil
function core.parse_relative_number(arg, relative_to) end

--- Send a join message.
---@param player_name string
function core.send_join_message(player_name) end

--- Send a leave message.
---@param player_name string
---@param timed_out boolean
function core.send_leave_message(player_name, timed_out) end

--- Hash a node position to a 48‑bit integer.
---@param pos vector
---@return integer
function core.hash_node_position(pos) end

--- Get node position from hash.
---@param hash integer
---@return vector
function core.get_position_from_hash(hash) end

--- Get item group rating.
---@param name string Item name
---@param group string
---@return integer rating
function core.get_item_group(name, group) end

--- Deprecated: alias for get_item_group.
function core.get_node_group(name, group) end

--- Get or create a raillike group ID.
---@param name string
---@return integer rating
function core.raillike_group(name) end

--- Get content ID for a node name.
---@param name string
---@return integer
function core.get_content_id(name) end

--- Get node name from content ID.
---@param content_id integer
---@return string
function core.get_name_from_content_id(content_id) end

--- Parse JSON.
---@param string string
---@param nullvalue? any Value to use for JSON null (default nil)
---@param return_error? boolean If true, return nil,err on failure
---@return any|nil, string? err
function core.parse_json(string, nullvalue, return_error) end

--- Write JSON.
---@param data any
---@param styled? boolean (default false)
---@return string|nil, string? err
function core.write_json(data, styled) end

--- Serialize a value to a string.
---@param value any
---@return string
function core.serialize(value) end

--- Deserialize a string.
---@param string string
---@param safe? boolean If true, strip functions (default false)
---@return any
function core.deserialize(string, safe) end

--- Compress data.
---@param data string
---@param method "deflate"|"zstd"
---@param level? integer Compression level (method‑specific)
---@return string compressed
function core.compress(data, method, level) end

--- Decompress data.
---@param compressed string
---@param method "deflate"|"zstd"
---@return string data
function core.decompress(compressed, method) end

--- Create a ColorString from RGBA components.
---@param red integer 0‑255
---@param green integer 0‑255
---@param blue integer 0‑255
---@param alpha? integer 0‑255
---@return string
function core.rgba(red, green, blue, alpha) end

--- Encode string to base64.
---@param s string
---@return string
function core.encode_base64(s) end

--- Decode base64 string.
---@param s string
---@return string|nil
function core.decode_base64(s) end

--- Check if a position is protected.
---@param pos vector
---@param name string Player name ("" for non‑player)
---@return boolean protected
function core.is_protected(pos, name) end

--- Record a protection violation.
---@param pos vector
---@param name string
function core.record_protection_violation(pos, name) end

--- Check if creative mode is enabled for a player.
---@param name string
---@return boolean
function core.is_creative_enabled(name) end

--- Check if an area is protected.
---@param pos1 vector
---@param pos2 vector
---@param player_name string
---@param interval? number (default 4)
---@return vector|false First protected position or false
function core.is_area_protected(pos1, pos2, player_name, interval) end

--- Rotate and place a node with prediction.
---@param itemstack ItemStack
---@param placer ObjectRef|nil
---@param pointed_thing table
---@param infinitestacks? boolean If true, don't modify stack
---@param orient_flags? {invert_wall?:boolean, force_wall?:boolean, force_ceiling?:boolean, force_floor?:boolean, force_facedir?:boolean}
---@param prevent_after_place? boolean
---@return ItemStack
function core.rotate_and_place(itemstack, placer, pointed_thing, infinitestacks, orient_flags, prevent_after_place) end

--- Rotate node (calls rotate_and_place with creative/sneak handling).
---@param itemstack ItemStack
---@param placer ObjectRef|nil
---@param pointed_thing table
function core.rotate_node(itemstack, placer, pointed_thing) end

--- Calculate knockback.
---@param player ObjectRef
---@param hitter ObjectRef|nil
---@param time_from_last_punch number|nil
---@param tool_capabilities table|nil
---@param dir vector
---@param distance number
---@param damage number
---@return number knockback
function core.calculate_knockback(player, hitter, time_from_last_punch, tool_capabilities, dir, distance, damage) end

--- Forceload a block.
---@param pos vector
---@param transient? boolean If true, not saved between runs
---@param limit? integer Max blocks (default from setting)
---@return boolean success
function core.forceload_block(pos, transient, limit) end

--- Stop forceloading a block.
---@param pos vector
---@param transient? boolean
function core.forceload_free_block(pos, transient) end

--- Compare mapblock status.
---@param pos vector
---@param condition "unknown"|"emerging"|"loaded"|"active"
---@return boolean|nil meets_condition (nil if condition invalid)
function core.compare_block_status(pos, condition) end

--- Request insecure environment (if mod is trusted).
---@return table|nil
function core.request_insecure_environment() end

--- Check if a global variable exists (without warning).
---@param name string
---@return boolean
function core.global_exists(name) end

--- Register a portable metatable for IPC/async.
---@param name string
---@param mt table
function core.register_portable_metatable(name, mt) end

--- Deprecated: alias for core namespace.
minetest = core

--- Deprecated: environment reference.
core.env = {}

-- Registered definition tables
---@type table<string, table>
core.registered_items = {}
---@type table<string, table>
core.registered_nodes = {}
---@type table<string, table>
core.registered_tools = {}
---@type table<string, table>
core.registered_craftitems = {}
---@type table<string, table>
core.registered_aliases = {}
---@type table<string, table>
core.registered_entities = {}
---@type table[]
core.registered_abms = {}
---@type table[]
core.registered_lbms = {}
---@type table<string, table>
core.registered_ores = {}
---@type table<string, table>
core.registered_biomes = {}
---@type table<string, table>
core.registered_decorations = {}
---@type table<string, table>
core.registered_chatcommands = {}
---@type table<string, PrivilegeDef>
core.registered_privileges = {}

-- Settings
---@class Settings
core.settings = {}

--- Get a setting value.
---@param name string
---@param default? any
---@return string|nil
function core.settings:get(name, default) end

--- Get a boolean setting.
---@param name string
---@param default? boolean
---@return boolean|nil
function core.settings:get_bool(name, default) end

--- Get a number setting.
---@param name string
---@param default? number
---@return number|nil
function core.settings:get_num(name, default) end

--- Get a NoiseParams setting.
---@param name string
---@return table|nil
function core.settings:get_np_group(name) end

--- Get flags setting as table.
---@param name string
---@return table<string,boolean>|nil
function core.settings:get_flags(name) end

--- Get a position setting.
---@param name string
---@return vector|nil
function core.settings:get_pos(name) end

--- Set a setting.
---@param name string
---@param value string
function core.settings:set(name, value) end

--- Set a boolean setting.
---@param name string
---@param value boolean
function core.settings:set_bool(name, value) end

--- Set a NoiseParams setting.
---@param name string
---@param value table
function core.settings:set_np_group(name, value) end

--- Set a position setting.
---@param name string
---@param value vector
function core.settings:set_pos(name, value) end

--- Remove a setting.
---@param name string
---@return boolean success
function core.settings:remove(name) end

--- Get all setting names.
---@return string[]
function core.settings:get_names() end

--- Check if a setting exists (ignores defaults).
---@param name string
---@return boolean
function core.settings:has(name) end

--- Write changes to file.
---@return boolean success
function core.settings:write() end

--- Convert to table.
---@return table<string, string>
function core.settings:to_table() end

--- Deprecated: use core.settings:get_pos.
function core.setting_get_pos(name) end