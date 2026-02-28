---@meta

--- Luanti (formerly Minetest) Core API
---@class CoreAPI
---@field PLAYER_MAX_HP_DEFAULT integer  -- default maximum player hit points (usually 20)
---@field CONTENT_IGNORE string   -- ID for "ignore" nodes
---@field CONTENT_UNKNOWN string  -- ID for "unknown" nodes
---@field CONTENT_AIR string      -- ID for "air" nodes
core = {}

--- Table form of a ColorSpec: each component 0-255.
---@class ColorSpecTable
---@field r integer
---@field g integer
---@field b integer
---@field a? integer (default 255)

--- A color value: table, integer ARGB8, or ColorString.
---@alias ColorSpec ColorSpecTable|integer|string

--- Table representation of an item stack.
---@class ItemTable
---@field name string
---@field count? integer
---@field wear? integer
---@field metadata? string

--- Any valid representation of an item: string, table, or ItemStack.
---@alias ItemRepresentation string|ItemTable|ItemStack

---@class ObjectProperties
---@field hp_max? integer
---@field breath_max? integer
---@field zoom_fov? number
---@field eye_height? number
---@field physical? boolean
---@field collide_with_objects? boolean
---@field collisionbox? number[]  -- [x1,y1,z1,x2,y2,z2]
---@field selectionbox? {[1]:number,[2]:number,[3]:number,[4]:number,[5]:number,[6]:number, rotate?:boolean}
---@field pointable? boolean|"blocking"
---@field visual? string
---@field visual_size? {x:number, y:number, z?:number}
---@field mesh? string
---@field textures? string[]
---@field colors? table[]
---@field node? {name:string, param1:integer, param2:integer}
---@field use_texture_alpha? boolean
---@field spritediv? {x:integer, y:integer}
---@field initial_sprite_basepos? {x:integer, y:integer}
---@field is_visible? boolean
---@field makes_footstep_sound? boolean
---@field automatic_rotate? number
---@field stepheight? number
---@field automatic_face_movement_dir? number
---@field automatic_face_movement_max_rotation_per_sec? number
---@field backface_culling? boolean
---@field glow? integer
---@field nametag? string
---@field nametag_color? ColorSpec
---@field nametag_bgcolor? ColorSpec|false
---@field nametag_fontsize? number|false
---@field nametag_scale_z? boolean
---@field infotext? string
---@field static_save? boolean
---@field damage_texture_modifier? string
---@field shaded? boolean
---@field show_on_minimap? boolean

--- ==============================
--- Utility functions
--- ==============================

--- Returns the currently loading mod's name (when loading a mod).
---@return string
function core.get_current_modname() end

--- Returns the directory path for a mod.
---@param modname string
---@return string|nil
function core.get_modpath(modname) end

--- Returns a list of mod names (optionally sorted by load order).
---@param load_order? boolean If true, sorted according to load order (since 5.16.0)
---@return string[]
function core.get_modnames(load_order) end

--- Returns a table containing information about the current game.
---@return {id: string, title: string, author: string, path: string}
function core.get_game_info() end

--- Returns the world directory path.
---@return string
function core.get_worldpath() end

--- Returns a path for mod‑specific persistent data (call during mod load).
---@return string
function core.get_mod_data_path() end

--- Returns true if the server is in singleplayer mode.
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

--- Checks if a feature (or set of features) is available.
---@param arg string|table<string, boolean>
---@return boolean available, table<string, boolean> missing
function core.has_feature(arg) end

--- Returns detailed information about a connected player.
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

--- Returns information about the player's window (size, scaling, etc.).
---@param player_name string
---@return PlayerWindowInfo|nil
function core.get_player_window_information(player_name) end

---@class PlayerWindowInfo
---@field size {x: integer, y: integer}
---@field max_formspec_size {x: number, y: number}
---@field real_gui_scaling number
---@field real_hud_scaling number
---@field touch_controls boolean

--- Checks whether a file system path exists.
---@param path string
---@return boolean
function core.path_exists(path) end

--- Creates a directory (including parent directories if needed).
---@param path string
---@return boolean success
function core.mkdir(path) end

--- Removes a directory (optionally recursively).
---@param path string
---@param recursive? boolean
---@return boolean success
function core.rmdir(path, recursive) end

--- Copies a directory recursively.
---@param source string
---@param destination string
---@return boolean success
function core.cpdir(source, destination) end

--- Moves a directory.
---@param source string
---@param destination string
---@return boolean success
function core.mvdir(source, destination) end

--- Returns list of entry names in a directory.
---@param path string
---@param is_dir? nil|boolean If nil, return all; if true, only subdirs; if false, only files
---@return string[]
function core.get_dir_list(path, is_dir) end

--- Replaces contents of a file atomically.
---@param path string
---@param content string
---@return boolean success
function core.safe_file_write(path, content) end

--- Returns a table containing components of the engine version.
---@return {project: string, string: string, proto_min: integer, proto_max: integer, hash?: string, is_dev: boolean}
function core.get_version() end

--- Returns the sha1 hash of data.
---@param data string
---@param raw? boolean Return raw bytes instead of hex digits (default false)
---@return string
function core.sha1(data, raw) end

--- Returns the sha256 hash of data.
---@param data string
---@param raw? boolean Return raw bytes instead of hex digits (default false)
---@return string
function core.sha256(data, raw) end

--- Converts a ColorSpec to a ColorString.
---@param colorspec ColorSpec
---@return string|nil
function core.colorspec_to_colorstring(colorspec) end

--- Converts a ColorSpec to raw RGBA bytes (string of 4 bytes).
---@param colorspec ColorSpec
---@return string
function core.colorspec_to_bytes(colorspec) end

--- Converts a ColorSpec into RGBA table form.
---@param colorspec ColorSpec
---@return ColorSpecTable|nil
function core.colorspec_to_table(colorspec) end

--- Returns a "day‑night ratio" value equivalent to the given "time of day".
---@param time_of_day number (0‑1)
---@return number ratio (0‑1)
function core.time_to_day_night_ratio(time_of_day) end

--- Encodes raw pixel data as a PNG image string.
---@param width integer
---@param height integer
---@param data table|string ColorSpec array or raw RGBA string
---@param compression? integer zlib compression level (0‑9)
---@return string PNG data
function core.encode_png(width, height, data, compression) end

--- URL‑encodes a string.
---@param str string
---@return string
function core.urlencode(str) end

--- ==============================
--- Logging
--- ==============================

--- Calls core.log with all arguments converted to string and tab‑separated (similar to print).
---@param ... any
function core.debug(...) end

--- Logs a message.
---@param level "error"|"warning"|"action"|"info"|"verbose"|"none"
---@param message string
function core.log(level, message) end

--- ==============================
--- Privileges
--- ==============================

--- Returns the privileges of a player as a set.
---@param player_name string
---@return table<string, boolean>
function core.get_player_privs(player_name) end

--- Converts string representation of privs into table form.
---@param str string
---@param delim? string (default ",")
---@return table<string, boolean>
function core.string_to_privs(str, delim) end

--- Returns the string representation of privs.
---@param privs table<string, boolean>
---@param delim? string (default ",")
---@return string
function core.privs_to_string(privs, delim) end

--- Checks player privileges.
---@param player_or_name string|PlayerRef
---@param ... string|table<string,boolean> List of privs or table
---@return boolean has_all, table<string,boolean> missing
function core.check_player_privs(player_or_name, ...) end

--- Returns true if the "password entry" matches the given password.
---@param name string
---@param entry string Password hash from auth database
---@param password string Plaintext password to check
---@return boolean matches
function core.check_password_entry(name, entry, password) end

--- Converts a name‑password pair to a password hash.
---@param name string
---@param raw_password string
---@return string hash
function core.get_password_hash(name, raw_password) end

--- Returns the IP address of an online player.
---@param name string
---@return string|nil
function core.get_player_ip(name) end

--- Returns the currently active auth handler.
---@return AuthHandler
function core.get_auth_handler() end

--- Notifies the engine that authentication data has been modified.
---@param name? string If omitted, all data may be modified
function core.notify_authentication_modified(name) end

--- Sets the password hash of a player.
---@param name string
---@param password_hash string
function core.set_player_password(name, password_hash) end

--- Sets the privileges of a player (replaces all).
---@param name string
---@param privs table<string, boolean>
function core.set_player_privs(name, privs) end

--- Grants or revokes privileges.
---@param name string
---@param changes table<string, boolean> true to grant, false to revoke
function core.change_player_privs(name, changes) end

--- Reloads authentication data from storage.
---@return boolean success
function core.auth_reload() end

--- ==============================
--- Chat
--- ==============================

--- Sends a chat message to all players.
---@param message string
function core.chat_send_all(message) end

--- Sends a chat message to a specific player.
---@param player_name string
---@param message string
function core.chat_send_player(player_name, message) end

--- Formats a chat message according to server settings.
---@param name string Player name
---@param message string
---@return string formatted
function core.format_chat_message(name, message) end

--- ==============================
--- Formspec
--- ==============================

--- Shows a formspec to a player.
---@param player_name string
---@param formname string
---@param formspec string
function core.show_formspec(player_name, formname, formspec) end

--- Closes a formspec for a player.
---@param player_name string
---@param formname string Use "" to close any formspec
function core.close_formspec(player_name, formname) end

--- Escapes a string for use in formspecs.
---@param str string
---@return string
function core.formspec_escape(str) end

--- Escapes a string for use in hypertext.
---@param str string
---@return string
function core.hypertext_escape(str) end

--- Parses a table event from formspec.
---@param event string
---@return {type:"INV"|"CHG"|"DCL", row?:integer, column?:integer}
function core.explode_table_event(event) end

--- Parses a textlist event.
---@param event string
---@return {type:"INV"|"CHG"|"DCL", index?:integer}
function core.explode_textlist_event(event) end

--- Parses a scrollbar event.
---@param event string
---@return {type:"INV"|"CHG"|"VAL", value?:integer}
function core.explode_scrollbar_event(event) end

--- Shows the death screen for a player.
---@param player PlayerRef
---@param reason? PlayerHPChangeReason
function core.show_death_screen(player, reason) end

--- ==============================
--- Registration functions
--- ==============================

--- Simple tile as a texture filename.
---@alias TileSimple string

--- Extended tile definition with optional fields.
---@class TileDefinitionTable
---@field name string Texture filename
---@field animation? TileAnimationDefinition
---@field backface_culling? boolean
---@field align_style? "node"|"world"|"user"
---@field scale? integer
---@field color? ColorSpec

---@alias TileDefinition TileSimple|TileDefinitionTable

---@class TileAnimationDefinition
---@field type "vertical_frames"|"sheet_2d"
---@field aspect_w? integer Width of a frame in pixels (for vertical_frames)
---@field aspect_h? integer Height of a frame in pixels (for vertical_frames)
---@field length? number Full loop length in seconds (for vertical_frames)
---@field frames_w? integer Width in number of frames (for sheet_2d)
---@field frames_h? integer Height in number of frames (for sheet_2d)
---@field frame_length? number Length of a single frame in seconds (for sheet_2d)

--- Simple item image as a texture filename.
---@alias ItemImageSimple string

--- Extended item image definition with optional animation.
---@class ItemImageDefinitionTable
---@field name string Texture filename
---@field animation? TileAnimationDefinition

---@alias ItemImageDefinition ItemImageSimple|ItemImageDefinitionTable

---@class Pointabilities
---@field nodes? table<string, boolean|"blocking">
---@field objects? table<string, boolean|"blocking">

---@class ToolCapabilities
---@field full_punch_interval number
---@field max_drop_level? integer
---@field groupcaps? table<string, {times:number[], uses:integer, maxlevel:integer}>
---@field damage_groups? table<string, integer>
---@field punch_attack_uses? integer

---@class WearColor
---@field blend? "constant"|"linear"
---@field color_stops table<number, ColorSpec>

---@class ItemSound
---@field breaks? SimpleSoundSpec
---@field eat? SimpleSoundSpec
---@field punch_use? SimpleSoundSpec
---@field punch_use_air? SimpleSoundSpec

---@class ItemDefinition
---@field description? string
---@field short_description? string
---@field groups? table<string, integer>
---@field inventory_image? ItemImageDefinition
---@field inventory_overlay? ItemImageDefinition
---@field wield_image? ItemImageDefinition
---@field wield_overlay? ItemImageDefinition
---@field wield_scale? {x:number, y:number, z:number}
---@field palette? string
---@field color? ColorSpec
---@field stack_max? integer (default 99)
---@field range? number (default 4.0)
---@field liquids_pointable? boolean
---@field pointabilities? Pointabilities
---@field light_source? integer (0..core.LIGHT_MAX)
---@field tool_capabilities? ToolCapabilities
---@field wear_color? WearColor|ColorSpec
---@field node_placement_prediction? string
---@field node_dig_prediction? string (default "air")
---@field touch_interaction? "long_dig_short_place"|"short_dig_long_place"|"user"|{pointed_nothing?:string, pointed_node?:string, pointed_object?:string}
---@field sound? ItemSound
--- Called when the 'place' key is used while pointing at a node. Returns leftover itemstack or nil.
---@field on_place? fun(itemstack:ItemStack, placer:PlayerRef|LuaEntityRef|nil, pointed_thing:pointed_thing): ItemStack|nil
--- Called when the 'place' key is used while not pointing at a node (e.g., right-click in air).
---@field on_secondary_use? fun(itemstack:ItemStack, user:PlayerRef|LuaEntityRef|nil, pointed_thing:pointed_thing): ItemStack|nil
--- Called when the item is dropped. Returns leftover itemstack and the spawned object reference.
---@field on_drop? fun(itemstack:ItemStack, dropper:PlayerRef|LuaEntityRef|nil, pos:vector): ItemStack, ObjectRef|nil
--- Called when a dropped item is punched by a player (pickup attempt). Returns leftover itemstack or nil.
---@field on_pickup? fun(itemstack:ItemStack, picker:PlayerRef|LuaEntityRef, pointed_thing:pointed_thing, time_from_last_punch?:number, ...): ItemStack|nil
--- Called when the 'punch/dig' key is used with the item. Returns leftover itemstack or nil.
---@field on_use? fun(itemstack:ItemStack, user:PlayerRef|LuaEntityRef|nil, pointed_thing:pointed_thing): ItemStack|nil
--- Called after using a tool to dig a node, for custom wear handling. Returns leftover itemstack or nil.
---@field after_use? fun(itemstack:ItemStack, user:PlayerRef|LuaEntityRef|nil, node:table, digparams:table): ItemStack|nil
---@field _custom? any

---@class NodeSound
---@field footstep? SimpleSoundSpec
---@field dig? SimpleSoundSpec|"__group"
---@field dug? SimpleSoundSpec
---@field place? SimpleSoundSpec
---@field place_failed? SimpleSoundSpec
---@field fall? SimpleSoundSpec

---@class NodeDropItem
---@field items string[]
---@field rarity? integer
---@field tools? string[]
---@field tool_groups? (string|string[])[]
---@field inherit_color? boolean

---@class NodeDrop
---@field max_items? integer
---@field items NodeDropItem[]

--- A box defined by six numbers: {x1, y1, z1, x2, y2, z2}
---@alias Box number[]

---@class NodeBox
---@field type "regular"|"fixed"|"leveled"|"wallmounted"|"connected"
---@field fixed? Box|Box[]               -- For "fixed" or "leveled"
---@field wall_top? Box                   -- For "wallmounted"
---@field wall_bottom? Box
---@field wall_side? Box
---@field connect_top? Box|Box[]          -- For "connected"
---@field connect_bottom? Box|Box[]
---@field connect_front? Box|Box[]
---@field connect_left? Box|Box[]
---@field connect_back? Box|Box[]
---@field connect_right? Box|Box[]
---@field disconnected_top? Box|Box[]
---@field disconnected_bottom? Box|Box[]
---@field disconnected_front? Box|Box[]
---@field disconnected_left? Box|Box[]
---@field disconnected_back? Box|Box[]
---@field disconnected_right? Box|Box[]
---@field disconnected? Box|Box[]
---@field disconnected_sides? Box|Box[]

---@class NodeDefinition : ItemDefinition
---@field drawtype? "normal"|"airlike"|"liquid"|"flowingliquid"|"glasslike"|"glasslike_framed"|"glasslike_framed_optional"|"allfaces"|"allfaces_optional"|"torchlike"|"signlike"|"plantlike"|"firelike"|"fencelike"|"raillike"|"nodebox"|"mesh"|"plantlike_rooted"
---@field visual_scale? number (default 1.0)
---@field tiles? TileDefinition[]
---@field overlay_tiles? TileDefinition[]
---@field special_tiles? TileDefinition[]
---@field use_texture_alpha? "opaque"|"clip"|"blend"|boolean (deprecated)
---@field palette? string
---@field post_effect_color? ColorSpec (default "#00000000")
---@field post_effect_color_shaded? boolean
---@field paramtype? "none"|"light"
---@field paramtype2? "none"|"flowingliquid"|"wallmounted"|"facedir"|"4dir"|"leveled"|"degrotate"|"meshoptions"|"color"|"colorfacedir"|"color4dir"|"colorwallmounted"|"glasslikeliquidlevel"|"colordegrotate"
---@field place_param2? integer
---@field wallmounted_rotate_vertical? boolean
---@field is_ground_content? boolean (default true)
---@field sunlight_propagates? boolean
---@field walkable? boolean (default true)
---@field pointable? boolean|"blocking" (default true)
---@field diggable? boolean (default true)
---@field climbable? boolean
---@field move_resistance? integer (0‑7)
---@field buildable_to? boolean
---@field floodable? boolean
---@field liquidtype? "none"|"source"|"flowing"
---@field liquid_alternative_flowing? string
---@field liquid_alternative_source? string
---@field liquid_viscosity? integer (0‑7)
---@field liquid_renewable? boolean (default true)
---@field liquid_move_physics? boolean|nil
---@field air_equivalent? boolean (deprecated)
---@field leveled? integer (0..leveled_max)
---@field leveled_max? integer (0‑127)
---@field liquid_range? integer (0‑8, default 8)
---@field drowning? integer
---@field damage_per_second? integer
---@field node_box? NodeBox
---@field connects_to? (string|string[])[]
---@field connect_sides? ("top"|"bottom"|"front"|"left"|"back"|"right")[]
---@field mesh? string
---@field selection_box? NodeBox
---@field collision_box? NodeBox
---@field legacy_facedir_simple? boolean
---@field legacy_wallmounted? boolean
---@field waving? integer (0‑3)
---@field sounds? NodeSound
---@field drop? string|NodeDrop
--- Called after adding node. Can set up metadata, etc.
---@field on_construct? fun(pos:vector)
--- Called before removing node.
---@field on_destruct? fun(pos:vector)
--- Called after removing node.
---@field after_destruct? fun(pos:vector, oldnode:table)
--- Called when a liquid is about to flood this node. Return true to prevent flooding.
---@field on_flood? fun(pos:vector, oldnode:table, newnode:table): boolean|nil
--- Called when node is about to be converted to an item, to preserve metadata in drops.
---@field preserve_metadata? fun(pos:vector, oldnode:table, oldmeta:table, drops:ItemStack[])
--- Called after node placed by player. Return true to prevent item consumption.
---@field after_place_node? fun(pos:vector, placer:ObjectRef|nil, itemstack:ItemStack, pointed_thing:pointed_thing): boolean|nil
--- Called after node dug by player.
---@field after_dig_node? fun(pos:vector, oldnode:table, oldmetadata:table, digger:ObjectRef|nil)
--- Return true if node can be dug, false otherwise.
---@field can_dig? fun(pos:vector, player?:PlayerRef): boolean
--- Called when node is punched.
---@field on_punch? fun(pos:vector, node:table, puncher:ObjectRef, pointed_thing:pointed_thing)
--- Called when player right-clicks node. Return leftover itemstack.
---@field on_rightclick? fun(pos:vector, node:table, clicker:ObjectRef, itemstack:ItemStack, pointed_thing:pointed_thing|nil): ItemStack|nil
--- Called when node is dug. Return true if successfully dug.
---@field on_dig? fun(pos:vector, node:table, digger:ObjectRef): boolean|nil
--- Called when node timer expires. Return true to restart timer.
---@field on_timer? fun(pos:vector, elapsed:number, node:table, timeout:number): boolean?
--- Called when a formspec for this node receives fields.
---@field on_receive_fields? fun(pos:vector, formname:string, fields:table<string,string>, sender:PlayerRef)
--- Return number of items allowed to move.
---@field allow_metadata_inventory_move? fun(pos:vector, from_list:string, from_index:integer, to_list:string, to_index:integer, count:integer, player:PlayerRef): integer
--- Return number of items allowed to put.
---@field allow_metadata_inventory_put? fun(pos:vector, listname:string, index:integer, stack:ItemStack, player:PlayerRef): integer
--- Return number of items allowed to take.
---@field allow_metadata_inventory_take? fun(pos:vector, listname:string, index:integer, stack:ItemStack, player:PlayerRef): integer
--- Called after inventory move.
---@field on_metadata_inventory_move? fun(pos:vector, from_list:string, from_index:integer, to_list:string, to_index:integer, count:integer, player:PlayerRef)
--- Called after inventory put.
---@field on_metadata_inventory_put? fun(pos:vector, listname:string, index:integer, stack:ItemStack, player:PlayerRef)
--- Called after inventory take.
---@field on_metadata_inventory_take? fun(pos:vector, listname:string, index:integer, stack:ItemStack, player:PlayerRef)
--- Called when explosion touches node, instead of removing node.
---@field on_blast? fun(pos:vector, intensity:number)
--- Called by the TNT mod when the node is about to ignite
---@field on_ignite? fun(pos:vector)
--- Called by the fire mod when the node catches fire
---@field on_burn? fun(pos:vector)
--- Called by the ctf_ranged mod when the node is shot
---@field on_ranged_shoot? fun(pos:vector, node:table, user:ObjectRef, weapon_type:string)
---@field mod_origin? string

--- Registers a node.
---@param name string
---@param definition NodeDefinition
function core.register_node(name, definition) end

--- Registers a tool.
---@param name string
---@param definition ItemDefinition
function core.register_tool(name, definition) end

--- Registers a craftitem.
---@param name string
---@param definition ItemDefinition
function core.register_craftitem(name, definition) end

---@class EntityDefinition
---@field initial_properties ObjectProperties
--- Called when object is instantiated.
---@field on_activate? fun(self:table, staticdata:string, dtime_s:number)
--- Called when object is about to be removed or unloaded.
---@field on_deactivate? fun(self:table, removal:boolean)
--- Called on every server tick.
---@field on_step? fun(self:table, dtime:number, moveresult:table)
--- Called when object is punched. Return true to prevent default damage.
---@field on_punch? fun(self:table, puncher:ObjectRef|nil, time_from_last_punch:number|nil, tool_capabilities:ToolCapabilities|nil, dir:vector, damage:number): boolean|nil
--- Called when object dies.
---@field on_death? fun(self:table, killer:ObjectRef|nil)
--- Called when object is right-clicked.
---@field on_rightclick? fun(self:table, clicker:ObjectRef)
--- Called after another object is attached to this one.
---@field on_attach_child? fun(self:table, child:ObjectRef)
--- Called after another object detaches from this one.
---@field on_detach_child? fun(self:table, child:ObjectRef)
--- Called after detaching from parent.
---@field on_detach? fun(self:table, parent:ObjectRef)
--- Return a string to be passed to on_activate when object is reloaded.
---@field get_staticdata? fun(self:table): string
---@field [string] any

--- Registers an entity.
---@param name string
---@param definition EntityDefinition
function core.register_entity(name, definition) end

---@class ABMDefinition
---@field label? string
---@field nodenames string|string[]
---@field neighbors? string|string[]
---@field without_neighbors? string|string[]
---@field interval number
---@field chance number
---@field min_y? integer
---@field max_y? integer
---@field catch_up? boolean
--- Function triggered for each qualifying node.
---@field action fun(pos:vector, node:table, active_object_count:integer, active_object_count_wider:integer)

--- Registers an ABM.
---@param definition ABMDefinition
function core.register_abm(definition) end

---@class LBMDefinition
---@field label? string
---@field name string
---@field nodenames string|string[]
---@field run_at_every_load? boolean
--- Function triggered for each qualifying node.
---@field action? fun(pos:vector, node:table, dtime_s:number)
--- Function triggered with list of all qualifying node positions at once.
---@field bulk_action? fun(pos_list:vector[], dtime_s:number)

--- Registers an LBM.
---@param definition LBMDefinition
function core.register_lbm(definition) end

--- Overrides fields of an existing item.
---@param name string
---@param redefinition table
---@param del_fields? string[]
function core.override_item(name, redefinition, del_fields) end

--- Unregisters an item.
---@param name string
function core.unregister_item(name) end

--- Registers an alias.
---@param alias string
---@param original_name string
function core.register_alias(alias, original_name) end

--- Registers an alias forcefully (overwrites existing).
---@param alias string
---@param original_name string
function core.register_alias_force(alias, original_name) end

---@class OreDefinition
---@field name? string
---@field ore_type "scatter"|"sheet"|"puff"|"blob"|"vein"|"stratum"
---@field ore string
---@field ore_param2? integer
---@field wherein string|string[]
---@field clust_scarcity integer
---@field clust_num_ores? integer   -- ignored by some ore types
---@field clust_size? integer       -- ignored by some ore types
---@field y_min integer
---@field y_max integer
---@field flags? string
---@field noise_threshold? number
---@field noise_params? NoiseParams
---@field biomes? string|string[]|integer[]
---@field column_height_min? integer
---@field column_height_max? integer
---@field column_midpoint_factor? number
---@field np_puff_top? NoiseParams
---@field np_puff_bottom? NoiseParams
---@field random_factor? number
---@field np_stratum_thickness? NoiseParams
---@field stratum_thickness? integer

--- Registers an ore.
---@param definition OreDefinition
---@return integer handle
function core.register_ore(definition) end

---@class BiomeDefinition
---@field name string
---@field node_dust? string
---@field node_top? string
---@field depth_top? integer
---@field node_filler? string
---@field depth_filler? integer
---@field node_stone? string
---@field node_water_top? string
---@field depth_water_top? integer
---@field node_water? string
---@field node_river_water? string
---@field node_riverbed? string
---@field depth_riverbed? integer
---@field node_cave_liquid? string|string[]
---@field node_dungeon? string
---@field node_dungeon_alt? string
---@field node_dungeon_stair? string
---@field y_max? integer
---@field y_min? integer
---@field max_pos? {x?:integer, y?:integer, z?:integer}
---@field min_pos? {x?:integer, y?:integer, z?:integer}
---@field vertical_blend? integer
---@field heat_point number
---@field humidity_point number
---@field weight? number

--- Registers a biome.
---@param definition BiomeDefinition
---@return integer handle
function core.register_biome(definition) end

--- Unregisters a biome.
---@param name string
function core.unregister_biome(name) end

---@class DecorationDefinition
---@field deco_type "simple"|"schematic"|"lsystem"
---@field place_on string|string[]
---@field sidelen? integer
---@field fill_ratio? number
---@field noise_params? NoiseParams
---@field biomes? string|string[]|integer[]
---@field y_min? integer
---@field y_max? integer
---@field spawn_by? string|string[]
---@field check_offset? -1|0|1
---@field num_spawn_by? integer
---@field flags? string
---@field decoration? string|string[] (simple)
---@field height? integer (simple)
---@field height_max? integer (simple)
---@field param2? integer (simple)
---@field param2_max? integer (simple)
---@field place_offset_y? integer
---@field schematic? string|table (schematic)
---@field replacements? table<string,string> (schematic)
---@field rotation? "0"|"90"|"180"|"270"|"random" (schematic)
---@field treedef? table (lsystem)

--- Registers a decoration.
---@param definition DecorationDefinition
---@return integer handle
function core.register_decoration(definition) end

---@class SchematicDefinition
---@field name? string
---@field size vector
---@field yslice_prob? {ypos:integer, prob:integer}[]
---@field data {name:string, prob?:integer, param2?:integer, force_place?:boolean}[]

--- Registers a schematic.
---@param definition SchematicDefinition
---@return integer handle
function core.register_schematic(definition) end

--- Clears all registered biomes.
function core.clear_registered_biomes() end

--- Clears all registered decorations.
function core.clear_registered_decorations() end

--- Clears all registered ores.
function core.clear_registered_ores() end

--- Clears all registered schematics.
function core.clear_registered_schematics() end

--- ==============================
--- Crafting
--- ==============================

---@class CraftRecipeShaped
---@field type? "shaped"
---@field output string
---@field recipe string[][]
---@field replacements? string[][]

---@class CraftRecipeShapeless
---@field type "shapeless"
---@field output string
---@field recipe string[]
---@field replacements? string[][]

---@class CraftRecipeCooking
---@field type "cooking"
---@field output string
---@field recipe string
---@field cooktime? number
---@field replacements? string[][]

---@class CraftRecipeFuel
---@field type "fuel"
---@field recipe string
---@field burntime? number
---@field replacements? string[][]

---@class CraftRecipeToolRepair
---@field type "toolrepair"
---@field additional_wear number

--- Registers a craft recipe.
---@param recipe CraftRecipeShaped|CraftRecipeShapeless|CraftRecipeToolRepair|CraftRecipeCooking|CraftRecipeFuel
function core.register_craft(recipe) end

--- Clears an existing craft recipe.
---@param recipe {output:string}|{type:string, recipe:any}
---@return boolean success
function core.clear_craft(recipe) end

--- ==============================
--- Chat commands
--- ==============================

---@class ChatCommandDefinition
---@field params? string
---@field description? string
---@field privs? table<string,boolean>|string[]
--- Function called when command is executed. Returns success boolean and optional message.
---@field func fun(name:string, param:string): (boolean|nil, string|nil)

--- Registers a chat command.
---@param name string
---@param definition ChatCommandDefinition
function core.register_chatcommand(name, definition) end

--- Overrides a chat command.
---@param name string
---@param redefinition table
function core.override_chatcommand(name, redefinition) end

--- Unregisters a chat command.
---@param name string
function core.unregister_chatcommand(name) end

--- ==============================
--- Privileges
--- ==============================

---@class PrivilegeDefinition
---@field description string
---@field give_to_singleplayer? boolean
---@field give_to_admin? boolean
--- Called when privilege is granted to a player.
---@field on_grant? fun(name:string, granter_name:string|nil)
--- Called when privilege is revoked from a player.
---@field on_revoke? fun(name:string, revoker_name:string|nil)

--- Registers a privilege.
---@param name string
---@param definition string|PrivilegeDefinition
function core.register_privilege(name, definition) end

--- ==============================
--- Authentication handler
--- ==============================

---@class AuthHandler
--- Get authentication data for player. Returns nil if player doesn't exist.
---@field get_auth fun(name:string): {password:string, privileges:table<string,boolean>, last_login?:number}|nil
--- Create new authentication data for player.
---@field create_auth fun(name:string, password:string)
--- Delete authentication data for player. Return success boolean.
---@field delete_auth fun(name:string): boolean
--- Set password for player.
---@field set_password fun(name:string, password:string)
--- Set privileges for player.
---@field set_privileges fun(name:string, privileges:table<string,boolean>)
--- Reload authentication data from storage. Return success boolean.
---@field reload fun(): boolean
--- Called when player joins, to record last login.
---@field record_login fun(name:string)
--- Return an iterator over all player names in auth database.
---@field iterate fun(): function

--- Registers an authentication handler.
---@param definition AuthHandler
function core.register_authentication_handler(definition) end

--- ==============================
--- Global callbacks
--- ==============================

--- Called every server step (usually 0.1s).
---@param func fun(dtime:number)
function core.register_globalstep(func) end

--- Called after all mods have finished loading.
---@param func fun()
function core.register_on_mods_loaded(func) end

--- Called during server shutdown before players are kicked.
---@param func fun()
function core.register_on_shutdown(func) end

--- Called after a node has been placed.
---@param func fun(pos:vector, newnode:table, placer:ObjectRef|nil, oldnode:table, itemstack:ItemStack, pointed_thing:pointed_thing): boolean|nil
function core.register_on_placenode(func) end

--- Called after a node has been dug.
---@param func fun(pos:vector, oldnode:table, digger:ObjectRef|nil)
function core.register_on_dignode(func) end

--- Called when a node is punched.
---@param func fun(pos:vector, node:table, puncher:ObjectRef, pointed_thing:pointed_thing)
function core.register_on_punchnode(func) end

--- Called after a mapchunk has been generated.
---@param func fun(minp:vector, maxp:vector, blockseed:integer)
function core.register_on_generated(func) end

--- Called when a new player enters the world for the first time.
---@param func fun(player:PlayerRef)
function core.register_on_newplayer(func) end

--- Called when a player joins the game.
---@param func fun(player:PlayerRef, last_login:number|nil)
function core.register_on_joinplayer(func) end

--- Called when a player leaves the game.
---@param func fun(player:PlayerRef, timed_out:boolean)
function core.register_on_leaveplayer(func) end

--- Called when a player dies.
---@param func fun(player:PlayerRef, reason:PlayerHPChangeReason)
function core.register_on_dieplayer(func) end

--- Called when a player is to be respawned.
---@param func fun(player:PlayerRef): boolean|nil
function core.register_on_respawnplayer(func) end

--- Called when a player's HP changes.
---@param func fun(player:PlayerRef, hp_change:integer, reason:PlayerHPChangeReason): (integer|nil, boolean|nil)
---@param modifier? boolean
function core.register_on_player_hpchange(func, modifier) end

---@class PlayerHPChangeReason
---@field type "set_hp"|"punch"|"fall"|"node_damage"|"drown"|"respawn"
---@field custom_type? string
---@field from "engine"|"mod"
---@field object? ObjectRef
---@field node? string
---@field node_pos? vector

--- Called when a player is punched.
---@param func fun(player:PlayerRef, hitter:ObjectRef|nil, time_from_last_punch:number|nil, tool_capabilities:ToolCapabilities|nil, dir:vector, damage:number): boolean|nil
function core.register_on_punchplayer(func) end

--- Called when the 'place/use' key was used while pointing a player.
---@param func fun(player:PlayerRef, clicker:ObjectRef)
function core.register_on_rightclickplayer(func) end

--- Called when a player says something.
---@param func fun(name:string, message:string): boolean|nil
function core.register_on_chat_message(func) end

--- Called when a chat command is triggered.
---@param func fun(name:string, command:string, params:string): boolean|nil
function core.register_on_chatcommand(func) end

--- Called when the server receives input from a player.
---@param func fun(player:PlayerRef, formname:string, fields:table<string,string>): boolean|nil
function core.register_on_player_receive_fields(func) end

--- Called when a player crafts something.
---@param func fun(itemstack:ItemStack, player:PlayerRef, old_craft_grid:ItemStack[], craft_inv:InvRef): ItemStack|nil
function core.register_on_craft(func) end

--- Called for craft prediction (before actual craft).
---@param func fun(itemstack:ItemStack, player:PlayerRef, old_craft_grid:ItemStack[], craft_inv:InvRef)
function core.register_on_craft_predict(func) end

--- Called when an item is eaten.
---@param func fun(hp_change:integer, replace_with_item:string|nil, itemstack:ItemStack, user:ObjectRef, pointed_thing:pointed_thing): ItemStack|nil
function core.register_on_item_eat(func) end

--- Called when an item is picked up.
---@param func fun(itemstack:ItemStack, picker:ObjectRef, pointed_thing:pointed_thing, time_from_last_punch?:number, ...): ItemStack|nil
function core.register_on_item_pickup(func) end

--- Determines how many items may be taken, put, or moved in a player inventory.
--- The callback only triggers when the player's inventory is the source or destination.
--- Return a number to limit the item count for this action.
--- For `take` actions only, returning -1 makes the source stack infinite.
---@param func fun(player:PlayerRef, action:string, inventory:InvRef, info:table): integer?
function core.register_allow_player_inventory_action(func) end

--- Called after an item take, put, or move event in a player inventory.
---@param func fun(player:PlayerRef, action:string, inventory:InvRef, info:table)
function core.register_on_player_inventory_action(func) end

--- Called when a player violates protection.
---@param func fun(pos:vector, name:string)
function core.register_on_protection_violation(func) end

--- Called when a privilege is granted.
---@param func fun(name:string, granter:string|nil, priv:string): boolean|nil
function core.register_on_priv_grant(func) end

--- Called when a privilege is revoked.
---@param func fun(name:string, revoker:string|nil, priv:string): boolean|nil
function core.register_on_priv_revoke(func) end

--- Called to decide whether a player may bypass the user limit.
---@param func fun(name:string, ip:string): boolean
function core.register_can_bypass_userlimit(func) end

--- Called when an incoming mod channel message is received.
---@param func fun(channel:string, sender:string, message:string)
function core.register_on_modchannel_message(func) end

--- Called after liquid nodes are transformed by the engine.
---@param func fun(pos_list:vector[], node_list:table[])
function core.register_on_liquid_transformed(func) end

--- Called soon after any nodes or node metadata have been modified.
---@param func fun(modified_blocks:table<integer,true>, modified_block_count:integer)
function core.register_on_mapblocks_changed(func) end

--- Called when a client connects (pre‑authentication).
---@param func fun(name:string, ip:string): string|nil
function core.register_on_prejoinplayer(func) end

--- Called when a client attempts to log into an account.
---@param func fun(name:string, ip:string, is_success:boolean)
function core.register_on_authplayer(func) end

--- Called when a player cheats.
---@param func fun(player:PlayerRef, cheat:{type:string})
function core.register_on_cheat(func) end

--- ==============================
--- Environment access
--- ==============================

--- Returns a list of connected players.
---@return PlayerRef[]
function core.get_connected_players() end

--- Returns a PlayerRef to a player (or nil if offline/doesn't exist).
---@param name string
---@return PlayerRef|nil
function core.get_player_by_name(name) end

--- Checks whether a player exists (regardless of online status).
---@param name string
---@return boolean
function core.player_exists(name) end

--- Checks whether the given name could be used as a player name.
---@param name string
---@return boolean
function core.is_valid_player_name(name) end

--- Returns true if the object is a player.
---@param obj ObjectRef
---@return boolean
function core.is_player(obj) end

--- Returns the node at the given position.
---@param pos vector
---@return {name: string, param1: integer, param2: integer}
function core.get_node(pos) end

--- Same as get_node but returns nil for unloaded areas.
---@param pos vector
---@return {name: string, param1: integer, param2: integer}|nil
function core.get_node_or_nil(pos) end

--- Low‑level get node (faster).
---@param x integer
---@param y integer
---@param z integer
---@return integer content_id, integer param1, integer param2, boolean pos_ok
function core.get_node_raw(x, y, z) end

--- Sets a node at the given position.
---@param pos vector
---@param node {name: string, param1?: integer, param2?: integer}
function core.set_node(pos, node) end

--- Alias for set_node.
---@param pos vector
---@param node table
function core.add_node(pos, node) end

--- Sets the same node at multiple positions.
---@param positions vector[]
---@param node {name: string, param1?: integer, param2?: integer}
function core.bulk_set_node(positions, node) end

--- Swaps a node (keeps metadata, no callbacks).
---@param pos vector
---@param node {name: string, param1?: integer, param2?: integer}
function core.swap_node(pos, node) end

--- Bulk swap nodes.
---@param positions vector[]
---@param node {name: string, param1?: integer, param2?: integer}
function core.bulk_swap_node(positions, node) end

--- Removes a node (sets to air).
---@param pos vector
function core.remove_node(pos) end

--- Gets the light value at the given position.
---@param pos vector
---@param timeofday? number (0‑1, nil for current)
---@return integer|nil (0‑15)
function core.get_node_light(pos, timeofday) end

--- Figures out the sunlight (or moonlight) value at pos.
---@param pos vector
---@param timeofday? number (0‑1, nil for current)
---@return integer|nil (0‑15)
function core.get_natural_light(pos, timeofday) end

--- Calculates artificial light from param1.
---@param param1 integer
---@return integer (0‑15)
function core.get_artificial_light(param1) end

--- Places a node with the same effects as a player would cause.
---@param pos vector
---@param node {name: string, param1?: integer, param2?: integer}
---@param placer? PlayerRef|LuaEntityRef
function core.place_node(pos, node, placer) end

--- Digs a node with the same effects as a player would cause.
---@param pos vector
---@param digger? ObjectRef
---@return boolean success
function core.dig_node(pos, digger) end

--- Punches a node.
---@param pos vector
---@param puncher? ObjectRef
function core.punch_node(pos, puncher) end

--- Changes a node into a falling node entity.
---@param pos vector
---@return boolean success, ObjectRef|nil entity
function core.spawn_falling_node(pos) end

--- Returns a table of positions of nodes that have metadata in a region.
---@param pos1 vector
---@param pos2 vector
---@return vector[]
function core.find_nodes_with_meta(pos1, pos2) end

--- Gets node metadata at the given position.
---@param pos vector
---@return NodeMetaRef
function core.get_meta(pos) end

--- Gets node timer at the given position.
---@param pos vector
---@return NodeTimerRef
function core.get_node_timer(pos) end

--- Spawns a Lua entity at the given position.
---@param pos vector
---@param name string
---@param staticdata? string
---@return LuaEntityRef|nil
function core.add_entity(pos, name, staticdata) end

--- Spawns an item entity at the given position.
---@param pos vector
---@param item ItemRepresentation
---@return ItemEntityRef|nil
function core.add_item(pos, item) end

--- Returns a list of ObjectRefs inside a radius.
---@param center vector
---@param radius number
---@return (PlayerRef|LuaEntityRef)[]
function core.get_objects_inside_radius(center, radius) end

--- Returns an iterator of valid objects inside a radius.
---@param center vector
---@param radius number
---@return fun(): (PlayerRef|LuaEntityRef)|nil
function core.objects_inside_radius(center, radius) end

--- Returns a list of ObjectRefs in an axis‑aligned area.
---@param min_pos vector
---@param max_pos vector
---@return ObjectRef[]
function core.get_objects_in_area(min_pos, max_pos) end

--- Returns an iterator of valid objects in an axis‑aligned area.
---@param min_pos vector
---@param max_pos vector
---@return fun(): (PlayerRef|LuaEntityRef)|nil
function core.objects_in_area(min_pos, max_pos) end

--- Sets the time of day.
---@param val number (0‑1)
function core.set_timeofday(val) end

--- Gets the time of day.
---@return number (0‑1)
function core.get_timeofday() end

--- Returns the time (in seconds) since the world was created.
---@return number|nil
function core.get_gametime() end

--- Returns the number of days elapsed since world creation.
---@return integer
function core.get_day_count() end

--- Finds a node near a position.
---@param pos vector
---@param radius number (maximum metric)
---@param nodenames string|string[]
---@param search_center? boolean (default false)
---@return vector|nil
function core.find_node_near(pos, radius, nodenames, search_center) end

--- Finds nodes in an area.
---@param pos1 vector
---@param pos2 vector
---@param nodenames string|string[]
---@param grouped? boolean
---@return vector[]|table<string,vector[]> positions, table<string,integer>? counts
function core.find_nodes_in_area(pos1, pos2, nodenames, grouped) end

--- Finds nodes in an area that have air above.
---@param pos1 vector
---@param pos2 vector
---@param nodenames string|string[]
---@return vector[]
function core.find_nodes_in_area_under_air(pos1, pos2, nodenames) end

---@class NoiseParams
---@field offset number
---@field scale number
---@field spread vector
---@field seed integer
---@field octaves integer
---@field persistence number
---@field lacunarity? number
---@field flags? string

--- Returns a world‑specific value noise instance.
---@param noiseparams NoiseParams
---@return ValueNoise
function core.get_value_noise(noiseparams) end

--- Deprecated, use get_value_noise.
---@param seeddiff integer
---@param octaves integer
---@param persistence number
---@param spread number|vector
---@return ValueNoise
function core.get_perlin(seeddiff, octaves, persistence, spread) end

--- Returns a voxel manipulator.
---@param pos1? vector
---@param pos2? vector
---@return VoxelManip
function core.get_voxel_manip(pos1, pos2) end

--- Sets the types of on‑generate notifications to collect.
---@param deco_ids? integer[]
---@param custom_ids? string[]
function core.set_gen_notify(flags, deco_ids, custom_ids) end

--- Returns the current gennotify settings.
---@return string flags, integer[] deco_ids, string[] custom_ids
function core.get_gen_notify() end

--- Returns the decoration ID for a decoration name.
---@param name string
---@return integer|nil
function core.get_decoration_id(name) end

--- Returns a mapgen object.
---@param objectname "voxelmanip"|"heightmap"|"biomemap"|"heatmap"|"humiditymap"|"gennotify"
---@return any
function core.get_mapgen_object(objectname) end

--- Returns the heat at a position.
---@param pos vector
---@return number|nil
function core.get_heat(pos) end

--- Returns the humidity at a position.
---@param pos vector
---@return number|nil
function core.get_humidity(pos) end

--- Returns biome data at a position.
---@param pos vector
---@return {biome: integer, heat: number, humidity: number}|nil
function core.get_biome_data(pos) end

--- Returns the biome ID for a biome name.
---@param name string
---@return integer|nil
function core.get_biome_id(name) end

--- Returns the biome name for a biome ID.
---@param id integer
---@return string|nil
function core.get_biome_name(id) end

--- Deprecated: use get_mapgen_setting.
---@return {mgname:string, seed:integer, chunksize:integer, water_level:integer, flags:string}
function core.get_mapgen_params() end

--- Deprecated: use set_mapgen_setting.
---@param params table
function core.set_mapgen_params(params) end

--- Returns the minimum and maximum possible generated node positions.
---@param mapgen_limit? integer
---@param chunksize? integer|vector
---@return vector minp, vector maxp
function core.get_mapgen_edges(mapgen_limit, chunksize) end

--- Returns the currently active chunksize of the mapgen (in blocks).
---@return vector
function core.get_mapgen_chunksize() end

--- Gets an active mapgen setting.
---@param name string
---@return string|nil
function core.get_mapgen_setting(name) end

--- Gets a mapgen setting as NoiseParams.
---@param name string
---@return NoiseParams|nil
function core.get_mapgen_setting_noiseparams(name) end

--- Sets a mapgen setting.
---@param name string
---@param value string
---@param override_meta? boolean (default false)
function core.set_mapgen_setting(name, value, override_meta) end

--- Sets a mapgen setting as NoiseParams.
---@param name string
---@param value NoiseParams
---@param override_meta? boolean (default false)
function core.set_mapgen_setting_noiseparams(name, value, override_meta) end

--- Sets a noiseparams setting.
---@param name string
---@param noiseparams NoiseParams
---@param set_default? boolean (default true)
function core.set_noiseparams(name, noiseparams, set_default) end

--- Gets a noiseparams setting.
---@param name string
---@return NoiseParams|nil
function core.get_noiseparams(name) end

--- Generates all registered ores within a VoxelManip.
---@param vm VoxelManip
---@param pos1? vector
---@param pos2? vector
function core.generate_ores(vm, pos1, pos2) end

--- Generates all registered decorations within a VoxelManip.
---@param vm VoxelManip
---@param pos1? vector
---@param pos2? vector
---@param use_mapgen_biomes? boolean (default false)
function core.generate_decorations(vm, pos1, pos2, use_mapgen_biomes) end

--- Clears all objects in the environment.
---@param options? {mode:"full"|"quick"}
function core.clear_objects(options) end

--- Loads mapblocks containing an area.
---@param pos1 vector
---@param pos2? vector
function core.load_area(pos1, pos2) end

--- Queues blocks in an area to be emerged asynchronously.
---@param pos1 vector
---@param pos2 vector
---@param callback? fun(blockpos:vector, action:integer, calls_remaining:integer, param:any)
---@param param? any
function core.emerge_area(pos1, pos2, callback, param) end

--- Deletes all mapblocks in an area.
---@param pos1 vector
---@param pos2 vector
function core.delete_area(pos1, pos2) end

--- Checks if there is a line of sight between two positions.
---@param pos1 vector
---@param pos2 vector
---@return boolean has_line_of_sight, vector|nil blocking_pos
function core.line_of_sight(pos1, pos2) end

--- Creates a raycast object.
---@param pos1 vector
---@param pos2 vector
---@param objects? boolean (default true)
---@param liquids? boolean (default false)
---@param pointabilities? Pointabilities
---@return Raycast
function core.raycast(pos1, pos2, objects, liquids, pointabilities) end

--- Finds a walkable path between two positions.
---@param pos1 vector
---@param pos2 vector
---@param searchdistance number
---@param max_jump number
---@param max_drop number
---@param algorithm? "A*_noprefetch"|"A*"|"Dijkstra" (default "A*_noprefetch")
---@return vector[]|nil
function core.find_path(pos1, pos2, searchdistance, max_jump, max_drop, algorithm) end

--- Spawns an L‑system tree.
---@param pos vector
---@param treedef table
function core.spawn_tree(pos, treedef) end

--- Spawns an L‑system tree onto a VoxelManip.
---@param vmanip VoxelManip
---@param pos vector
---@param treedef table
function core.spawn_tree_on_vmanip(vmanip, pos, treedef) end

--- Adds a node to the liquid flow update queue.
---@param pos vector
function core.transforming_liquid_add(pos) end

--- Returns the maximum level for a leveled node.
---@param pos vector
---@return integer
function core.get_node_max_level(pos) end

--- Returns the current level of a leveled node.
---@param pos vector
---@return integer
function core.get_node_level(pos) end

--- Sets the level of a leveled node.
---@param pos vector
---@param level integer
function core.set_node_level(pos, level) end

--- Adds to the level of a leveled node.
---@param pos vector
---@param add integer
---@return integer new_level
function core.add_node_level(pos, add) end

--- Returns actual node boxes after applying rotations.
---@param box_type "node_box"|"collision_box"|"selection_box"
---@param pos vector
---@param node? table
---@return {[1]:number, [2]:number, [3]:number, [4]:number, [5]:number, [6]:number}[]
function core.get_node_boxes(box_type, pos, node) end

--- Fixes lighting in an area.
---@param pos1 vector
---@param pos2 vector
---@return boolean success
function core.fix_light(pos1, pos2) end

--- Causes an unsupported falling node to fall (single).
---@param pos vector
function core.check_single_for_falling(pos) end

--- Causes falling nodes to fall and propagate.
---@param pos vector
function core.check_for_falling(pos) end

--- Returns a player spawn y coordinate at (x,z).
---@param x integer
---@param z integer
---@return integer|nil
function core.get_spawn_level(x, z) end

--- ==============================
--- Mod channels
--- ==============================

--- Joins a mod channel.
---@param channel_name string
---@return ModChannel
function core.mod_channel_join(channel_name) end

--- ==============================
--- Inventory
--- ==============================

--- Gets an inventory reference.
---@param location {type:"player", name:string}|{type:"node", pos:vector}|{type:"detached", name:string}
---@return InvRef
function core.get_inventory(location) end

---@class DetachedInventoryCallbacks
--- Return number of items allowed to move.
---@field allow_move? fun(inv:InvRef, from_list:string, from_index:integer, to_list:string, to_index:integer, count:integer, player:PlayerRef): integer
--- Return number of items allowed to put.
---@field allow_put? fun(inv:InvRef, listname:string, index:integer, stack:ItemStack, player:PlayerRef): integer
--- Return number of items allowed to take.
---@field allow_take? fun(inv:InvRef, listname:string, index:integer, stack:ItemStack, player:PlayerRef): integer
--- Called after items moved.
---@field on_move? fun(inv:InvRef, from_list:string, from_index:integer, to_list:string, to_index:integer, count:integer, player:PlayerRef)
--- Called after items put.
---@field on_put? fun(inv:InvRef, listname:string, index:integer, stack:ItemStack, player:PlayerRef)
--- Called after items taken.
---@field on_take? fun(inv:InvRef, listname:string, index:integer, stack:ItemStack, player:PlayerRef)

--- Creates a detached inventory.
---@param name string
---@param callbacks DetachedInventoryCallbacks
---@param player_name? string
---@return InvRef
function core.create_detached_inventory(name, callbacks, player_name) end

--- Removes a detached inventory.
---@param name string
---@return boolean success
function core.remove_detached_inventory(name) end

--- Executes an item eat action.
---@param hp_change integer
---@param replace_with_item string|nil
---@param itemstack ItemStack
---@param user ObjectRef
---@param pointed_thing table
---@return ItemStack|nil
function core.do_item_eat(hp_change, replace_with_item, itemstack, user, pointed_thing) end

--- Returns a function wrapper for core.do_item_eat.
---@param hp_change integer
---@param replace_with_item? string
---@return fun(itemstack:ItemStack, user:ObjectRef, pointed_thing:table): ItemStack|nil
function core.item_eat(hp_change, replace_with_item) end

--- ==============================
--- Item helpers
--- ==============================

--- Default node placement function.
---@param itemstack ItemStack
---@param placer ObjectRef|nil
---@param pointed_thing table
---@param param2? integer
---@param prevent_after_place? boolean
---@return ItemStack, vector|nil
function core.item_place_node(itemstack, placer, pointed_thing, param2, prevent_after_place) end

--- Deprecated.
function core.item_place_object(itemstack, placer, pointed_thing) end

--- Default item placement dispatcher.
---@param itemstack ItemStack
---@param placer ObjectRef|nil
---@param pointed_thing table
---@param param2? integer
---@return ItemStack, vector|nil
function core.item_place(itemstack, placer, pointed_thing, param2) end

--- Default item pickup handler.
---@param itemstack ItemStack
---@param picker PlayerRef|LuaEntityRef
---@param pointed_thing table
---@param time_from_last_punch? number
---@param ... any
---@return ItemStack
function core.item_pickup(itemstack, picker, pointed_thing, time_from_last_punch, ...) end

--- Default secondary use (does nothing).
---@param itemstack ItemStack
---@param user PlayerRef|LuaEntityRef
---@param pointed_thing table
---@return ItemStack|nil
function core.item_secondary_use(itemstack, user, pointed_thing) end

--- Default drop function.
---@param itemstack ItemStack
---@param dropper ObjectRef|nil
---@param pos vector
---@return ItemStack leftover, LuaEntityRef|nil entity
function core.item_drop(itemstack, dropper, pos) end

--- Default node punch callback.
---@param pos vector
---@param node table
---@param puncher PlayerRef|LuaEntityRef
---@param pointed_thing table
function core.node_punch(pos, node, puncher, pointed_thing) end

--- Default node dig callback.
---@param pos vector
---@param node table
---@param digger ObjectRef
function core.node_dig(pos, node, digger) end

--- ==============================
--- Sounds
--- ==============================

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

--- Plays a sound.
---@param spec SimpleSoundSpec
---@param parameters SoundParams
---@param ephemeral? boolean (default false)
---@return integer|nil handle
function core.sound_play(spec, parameters, ephemeral) end

--- Stops a sound.
---@param handle integer
function core.sound_stop(handle) end

--- Fades a sound.
---@param handle integer
---@param step number
---@param gain number
function core.sound_fade(handle, step, gain) end

--- ==============================
--- Async
--- ==============================

--- Queues a function to be run in an async environment.
---@param func function
---@param callback function
---@param ... any
---@return AsyncJob
function core.handle_async(func, callback, ...) end

--- Registers a file to be loaded in each async environment.
---@param path string
function core.register_async_dofile(path) end

--- Registers a file to be loaded in each mapgen environment.
---@param path string
function core.register_mapgen_script(path) end

--- Saves data for retrieval via gennotify (mapgen environment only).
---@param id string
---@param data any
---@return boolean success
function core.save_gen_notify(id, data) end

--- ==============================
--- Timing
--- ==============================

--- Reference to a delayed job created by core.after.
---@class AfterJob
--- Cancels the job. Returns true if successfully cancelled (job not yet executed).
---@field cancel fun(self:AfterJob): boolean

--- Calls a function after a delay. Returns a job table with a cancel method.
---@param time number (seconds, may be fractional)
---@param func function
---@param ... any
---@return AfterJob
function core.after(time, func, ...) end

--- ==============================
--- Server
--- ==============================

--- Returns the server status string.
---@param name string
---@param joined boolean
---@return string|nil
function core.get_server_status(name, joined) end

--- Returns the server uptime in seconds.
---@return number
function core.get_server_uptime() end

--- Returns the current maximum server lag.
---@return number|nil
function core.get_server_max_lag() end

--- Removes a player from the database (if not connected).
---@param name string
---@return integer (0=success,1=no such player,2=player connected)
function core.remove_player(name) end

--- Removes player authentication data.
---@param name string
---@return boolean success
function core.remove_player_auth(name) end

--- Dynamically adds media to clients.
---@param options {filename?:string, filepath?:string, filedata?:string, to_player?:string, ephemeral?:boolean, client_cache?:boolean}
---@param callback? fun(name:string)
---@return boolean accepted
function core.dynamic_add_media(options, callback) end

--- Requests server shutdown.
---@param message? string
---@param reconnect? boolean
---@param delay? number (seconds)
function core.request_shutdown(message, reconnect, delay) end

--- Cancels current delayed shutdown.
function core.cancel_shutdown_requests() end

--- ==============================
--- IPC
--- ==============================

--- Reads a value from the shared data area.
---@param key string
---@return any
function core.ipc_get(key) end

--- Writes a value to the shared data area.
---@param key string
---@param value any
function core.ipc_set(key, value) end

--- Compare‑and‑swap.
---@param key string
---@param old_value any
---@param new_value any
---@return boolean success
function core.ipc_cas(key, old_value, new_value) end

--- Blocks until a value is present at the key.
---@param key string
---@param timeout integer (milliseconds)
---@return boolean success
function core.ipc_poll(key, timeout) end

--- ==============================
--- Bans
--- ==============================

--- Returns a list of all bans as string.
---@return string
function core.get_ban_list() end

--- Returns a description of bans matching IP or name.
---@param ip_or_name string
---@return string
function core.get_ban_description(ip_or_name) end

--- Bans a currently connected player.
---@param name string
---@return boolean success
function core.ban_player(name) end

--- Unbans an IP or name.
---@param ip_or_name string
---@return boolean success
function core.unban_player_or_ip(ip_or_name) end

--- Kicks a player.
---@param name string
---@param reason? string
---@param reconnect? boolean
---@return boolean success
function core.kick_player(name, reason, reconnect) end

--- Disconnects a player (without "Kicked:" prefix).
---@param name string
---@param reason? string
---@param reconnect? boolean
---@return boolean success
function core.disconnect_player(name, reason, reconnect) end

--- ==============================
--- Particles
--- ==============================

---@class ParticleDefinition
---@field pos? vector
---@field velocity? vector
---@field acceleration? vector
---@field expirationtime? number
---@field size? number
---@field collisiondetection? boolean
---@field collision_removal? boolean
---@field object_collision? boolean
---@field vertical? boolean
---@field texture? string|table
---@field playername? string
---@field animation? TileAnimationDefinition
---@field glow? integer (0‑14)
---@field node? {name:string, param2?:integer}
---@field node_tile? integer
---@field drag? vector
---@field jitter? {min:number, max:number, bias?:number}
---@field bounce? {min:number, max:number, bias?:number}

--- Spawns a single particle.
---@param def ParticleDefinition
function core.add_particle(def) end

---@class ParticleSpawnerDefinition
---@field amount integer
---@field time number
---@field size? number
---@field collisiondetection? boolean
---@field collision_removal? boolean
---@field object_collision? boolean
---@field attached? ObjectRef
---@field vertical? boolean
---@field texture? string|table
---@field playername? string
---@field exclude_player? string
---@field animation? TileAnimationDefinition
---@field glow? integer
---@field node? {name:string, param2?:integer}
---@field node_tile? integer
---@field minpos? vector
---@field maxpos? vector
---@field minvel? vector
---@field maxvel? vector
---@field minacc? vector
---@field maxacc? vector
---@field minexptime? number
---@field maxexptime? number
---@field minsize? number
---@field maxsize? number
---@field pos? vector|{min:vector, max:vector, bias?:number}
---@field vel? vector|{min:vector, max:vector, bias?:number}
---@field acc? vector|{min:vector, max:vector, bias?:number}
---@field exptime? {min:number, max:number, bias?:number}
---@field size_tween? table
---@field texpool? (string|table)[]
---@field attract? {kind:"none"|"point"|"line"|"plane", strength:{min:number, max:number, bias?:number}, origin?:vector, direction?:vector, origin_attached?:ObjectRef, direction_attached?:ObjectRef, die_on_contact?:boolean}
---@field radius? {min:number, max:number, bias?:number}|vector

--- Adds a particle spawner.
---@param def ParticleSpawnerDefinition
---@return integer id
function core.add_particlespawner(def) end

--- Deletes a particle spawner.
---@param id integer
---@param player? string
function core.delete_particlespawner(id, player) end

--- ==============================
--- Schematics
--- ==============================

--- Creates a schematic from a region.
---@param p1 vector
---@param p2 vector
---@param probability_list? {pos:vector, prob:integer}[]
---@param filename string
---@param slice_prob_list? {ypos:integer, prob:integer}[]
function core.create_schematic(p1, p2, probability_list, filename, slice_prob_list) end

--- Places a schematic.
---@param pos vector
---@param schematic string|table
---@param rotation? "0"|"90"|"180"|"270"|"random"
---@param replacements? table<string,string>
---@param force_placement? boolean
---@param flags? string
---@return boolean|nil success
function core.place_schematic(pos, schematic, rotation, replacements, force_placement, flags) end

--- Places a schematic onto a VoxelManip.
---@param vmanip VoxelManip
---@param pos vector
---@param schematic string|table
---@param rotation? string
---@param replacements? table
---@param force_placement? boolean
---@param flags? string
---@return boolean|nil fits
function core.place_schematic_on_vmanip(vmanip, pos, schematic, rotation, replacements, force_placement, flags) end

--- Serializes a schematic to a string.
---@param schematic string|table
---@param format "mts"|"lua"
---@param options? {lua_use_comments?:boolean, lua_num_indent_spaces?:integer}
---@return string|nil
function core.serialize_schematic(schematic, format, options) end

--- Reads a schematic into a table.
---@param schematic string|table
---@param options? {write_yslice_prob?:"none"|"low"|"all"}
---@return table|nil
function core.read_schematic(schematic, options) end

--- ==============================
--- HTTP
--- ==============================

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

---@class HTTPApiTable
--- Perform HTTP request asynchronously and call callback with result.
---@field fetch fun(req:HTTPRequest, callback:fun(res:HTTPRequestResult))
--- Perform HTTP request asynchronously and return handle.
---@field fetch_async fun(req:HTTPRequest): integer
--- Retrieve result for async fetch handle.
---@field fetch_async_get fun(handle:integer): HTTPRequestResult

--- Requests the HTTP API table (if mod is trusted).
---@return HTTPApiTable|nil
function core.request_http_api() end

--- ==============================
--- Storage
--- ==============================

--- Returns a reference to mod‑private storage.
---@return ModStorage
function core.get_mod_storage() end

--- ==============================
--- Miscellaneous
--- ==============================

--- A color value in string form (e.g., "#FF0000", "red", "#0F0#80").
---@alias ColorString string

--- Returns an escape sequence that sets the text color.
---@param color ColorString
---@return string
function core.get_color_escape_sequence(color) end

--- Returns a string with `message` colorized using `color`.
--- Equivalent to `core.get_color_escape_sequence(color) .. message .. core.get_color_escape_sequence("#fff")`.
---@param color ColorString
---@param message string
---@return string
function core.colorize(color, message) end

--- Returns an escape sequence that sets the background color.
---@param color ColorString
---@return string
function core.get_background_escape_sequence(color) end

--- Removes foreground color escape sequences from a string.
---@param str string
---@return string
function core.strip_foreground_colors(str) end

--- Removes background color escape sequences from a string.
---@param str string
---@return string
function core.strip_background_colors(str) end

--- Removes all color escape sequences from a string.
---@param str string
---@return string
function core.strip_colors(str) end

--- Removes all escape sequences (including translations) from a string.
---@param str string
---@return string
function core.strip_escapes(str) end

--- Replaces the definition of a built‑in HUD element.
---@param name "breath"|"health"|"minimap"|"hotbar"
---@param def HUDDefinition
function core.hud_replace_builtin(name, def) end

--- Parses a relative number (tilde notation).
---@param arg string
---@param relative_to number
---@return number|nil
function core.parse_relative_number(arg, relative_to) end

--- Sends a join message (can be overridden).
---@param player_name string
function core.send_join_message(player_name) end

--- Sends a leave message (can be overridden).
---@param player_name string
---@param timed_out boolean
function core.send_leave_message(player_name, timed_out) end

--- Hashes a node position to a 48‑bit integer.
---@param pos vector
---@return integer
function core.hash_node_position(pos) end

--- Returns a node position from a hash.
---@param hash integer
---@return vector
function core.get_position_from_hash(hash) end

--- Returns the rating of a group for an item.
---@param name string
---@param group string
---@return integer
function core.get_item_group(name, group) end

--- Deprecated alias for get_item_group.
function core.get_node_group(name, group) end

--- Returns the rating of a connect_to_raillike group.
---@param name string
---@return integer
function core.raillike_group(name) end

--- Returns the content ID for a node name.
---@param name string
---@return integer
function core.get_content_id(name) end

--- Returns the node name for a content ID.
---@param content_id integer
---@return string
function core.get_name_from_content_id(content_id) end

--- Parses JSON.
---@param string string
---@param nullvalue? any
---@param return_error? boolean
---@return any|nil, string? err
function core.parse_json(string, nullvalue, return_error) end

--- Writes JSON.
---@param data any
---@param styled? boolean
---@return string|nil, string? err
function core.write_json(data, styled) end

--- Serializes a value to a string.
---@param value any
---@return string
function core.serialize(value) end

--- Deserializes a string.
---@param string string
---@param safe? boolean
---@return any
function core.deserialize(string, safe) end

--- Compresses data.
---@param data string
---@param method "deflate"|"zstd"
---@param level? integer
---@return string
function core.compress(data, method, level) end

--- Decompresses data.
---@param compressed string
---@param method "deflate"|"zstd"
---@return string
function core.decompress(compressed, method) end

--- Returns a ColorString from RGBA components.
---@param red integer
---@param green integer
---@param blue integer
---@param alpha? integer
---@return string
function core.rgba(red, green, blue, alpha) end

--- Encodes a string in base64.
---@param s string
---@return string
function core.encode_base64(s) end

--- Decodes a base64 string.
---@param s string
---@return string|nil
function core.decode_base64(s) end

--- Checks if a position is protected.
---@param pos vector
---@param name string
---@return boolean
function core.is_protected(pos, name) end

--- Records a protection violation.
---@param pos vector
---@param name string
function core.record_protection_violation(pos, name) end

--- Checks if creative mode is enabled for a player.
---@param name string
---@return boolean
function core.is_creative_enabled(name) end

--- Checks if an area is protected.
---@param pos1 vector
---@param pos2 vector
---@param player_name string
---@param interval? number
---@return vector|false
function core.is_area_protected(pos1, pos2, player_name, interval) end

--- Rotates and places a node with prediction.
---@param itemstack ItemStack
---@param placer ObjectRef|nil
---@param pointed_thing table
---@param infinitestacks? boolean
---@param orient_flags? {invert_wall?:boolean, force_wall?:boolean, force_ceiling?:boolean, force_floor?:boolean, force_facedir?:boolean}
---@param prevent_after_place? boolean
---@return ItemStack
function core.rotate_and_place(itemstack, placer, pointed_thing, infinitestacks, orient_flags, prevent_after_place) end

--- Rotates a node (calls rotate_and_place with creative/sneak handling).
---@param itemstack ItemStack
---@param placer ObjectRef|nil
---@param pointed_thing table
function core.rotate_node(itemstack, placer, pointed_thing) end

--- Calculates knockback.
---@param player PlayerRef
---@param hitter ObjectRef|nil
---@param time_from_last_punch number|nil
---@param tool_capabilities ToolCapabilities|nil
---@param dir vector
---@param distance number
---@param damage number
---@return number
function core.calculate_knockback(player, hitter, time_from_last_punch, tool_capabilities, dir, distance, damage) end

--- Forceloads a block.
---@param pos vector
---@param transient? boolean
---@param limit? integer
---@return boolean success
function core.forceload_block(pos, transient, limit) end

--- Stops forceloading a block.
---@param pos vector
---@param transient? boolean
function core.forceload_free_block(pos, transient) end

--- Compares mapblock status.
---@param pos vector
---@param condition "unknown"|"emerging"|"loaded"|"active"
---@return boolean|nil
function core.compare_block_status(pos, condition) end

--- Requests an insecure environment (if mod is trusted).
---@return table|nil
function core.request_insecure_environment() end

--- Checks if a global variable exists (without warning).
---@param name string
---@return boolean
function core.global_exists(name) end

--- Registers a portable metatable for IPC/async.
---@param name string
---@param mt table
function core.register_portable_metatable(name, mt) end

--- ==============================
--- Item handling (additional)
--- ==============================

--- Returns list of itemstrings dropped by node when dug with given tool.
---@param node string|table
---@param toolname? string
---@param tool? ItemStack
---@param digger? ObjectRef
---@param pos? vector
---@return string[]
function core.get_node_drops(node, toolname, tool, digger, pos) end

--- Simulates a crafting operation and returns output and decremented input.
---@param input {method:"normal"|"cooking"|"fuel", width:integer, items:ItemStack[]}
---@return {item:ItemStack, time:number, replacements:ItemStack[]} output, table decremented_input
function core.get_craft_result(input) end

--- Returns last registered recipe for output item.
---@param output string
---@return {method:string, width:integer, items:ItemStack[]}|nil
function core.get_craft_recipe(output) end

--- Returns all registered recipes for query item.
---@param item string
---@return {method:string, width:integer, items:ItemStack[], output:string}[]|nil
function core.get_all_craft_recipes(item) end

--- Handles drops from a dug node: default is to put them into digger's inventory.
---@param pos vector
---@param drops string[]
---@param digger PlayerRef|LuaEntityRef
function core.handle_node_drops(pos, drops, digger) end

--- Creates an item string with palette index for hardware coloring.
---@param item ItemStack|string|table
---@param palette_index integer
---@return string
function core.itemstring_with_palette(item, palette_index) end

--- Creates an item string with static color.
---@param item ItemStack|string|table
---@param colorstring string
---@return string
function core.itemstring_with_color(item, colorstring) end

--- Returns position of pointed thing (node or object) or nil.
---@param pointed_thing pointed_thing
---@param above? boolean Return above position for node
---@return vector|nil
function core.get_pointed_thing_position(pointed_thing, above) end

--- Returns a string for an inventory cube image.
---@param img1 string
---@param img2 string
---@param img3 string
---@return string
function core.inventorycube(img1, img2, img3) end

--- Converts direction vector to facedir value.
---@param dir vector
---@param is6d? boolean Include up/down (6‑directional)
---@return integer
function core.dir_to_facedir(dir, is6d) end

--- Converts facedir to direction vector.
---@param facedir integer
---@return vector
function core.facedir_to_dir(facedir) end

--- Converts direction vector to 4dir value.
---@param dir vector
---@return integer
function core.dir_to_fourdir(dir) end

--- Converts 4dir to direction vector.
---@param fourdir integer
---@return vector
function core.fourdir_to_dir(fourdir) end

--- Converts direction vector to wallmounted value.
---@param dir vector
---@return integer
function core.dir_to_wallmounted(dir) end

--- Converts wallmounted to direction vector.
---@param wallmounted integer
---@return vector
function core.wallmounted_to_dir(wallmounted) end

--- Converts direction vector to yaw (radians).
---@param dir vector
---@return number
function core.dir_to_yaw(dir) end

--- Converts yaw (radians) to direction vector.
---@param yaw number
---@return vector
function core.yaw_to_dir(yaw) end

--- Returns true if paramtype2 includes color information.
---@param ptype string
---@return boolean
function core.is_colored_paramtype(ptype) end

--- Strips everything but color from param2 based on paramtype2.
---@param param2 integer
---@param paramtype2 string
---@return integer|nil
function core.strip_param2_color(param2, paramtype2) end

--- ==============================
--- Rollback
--- ==============================

--- Returns actions performed on nodes in an area.
---@param pos vector
---@param range number
---@param seconds number
---@param limit integer
---@return {actor:string, pos:vector, time:number, oldnode:table, newnode:table}[]
function core.rollback_get_node_actions(pos, range, seconds, limit) end

--- Reverts latest actions by an actor.
---@param actor string (e.g. "player:<name>")
---@param seconds number
---@return boolean success, string log_messages
function core.rollback_revert_actions_by(actor, seconds) end

--- ==============================
--- Helper functions
--- ==============================

--- Returns exact position on the surface of a pointed node.
---@param placer ObjectRef
---@param pointed_thing pointed_thing
---@return vector
function core.pointed_thing_to_face_pos(placer, pointed_thing) end

--- Simulates tool use and returns added wear.
---@param uses integer
---@param initial_wear? integer (default 0)
---@return integer
function core.get_tool_wear_after_use(uses, initial_wear) end

--- Simulates digging a node with given capabilities.
---@param groups table<string,integer> Node groups
---@param tool_capabilities ToolCapabilities
---@param wear? integer (default 0)
---@return {diggable:boolean, time:number, wear:integer}
function core.get_dig_params(groups, tool_capabilities, wear) end

--- Simulates hitting an object with given capabilities.
---@param groups table<string,integer> Object armor groups
---@param tool_capabilities ToolCapabilities
---@param time_from_last_punch? number
---@param wear? integer (default 0)
---@return {hp:integer, wear:integer}
function core.get_hit_params(groups, tool_capabilities, time_from_last_punch, wear) end

--- Adds newlines to string to keep it within character limit.
---@param str string
---@param limit integer
---@param as_table? boolean Return table of lines
---@return string|string[]
function core.wrap_text(str, limit, as_table) end

--- Converts position to human‑readable string.
---@param pos vector
---@param decimal_places? integer
---@return string
function core.pos_to_string(pos, decimal_places) end

--- Parses position from string.
---@param str string
---@return vector|nil
function core.string_to_pos(str) end

--- Parses area string "(x1,y1,z1) (x2,y2,z2)" with optional tilde notation.
---@param str string
---@param relative_to? vector
---@return vector pos1, vector pos2
function core.string_to_area(str, relative_to) end

--- Returns true for 'y', 'yes', 'true' or non‑zero number.
---@param arg any
---@return boolean
function core.is_yes(arg) end

--- Returns true if number is NaN.
---@param arg number
---@return boolean
function core.is_nan(arg) end

--- Returns time with microsecond precision (not necessarily wall time).
---@return number
function core.get_us_time() end

--- ==============================
--- Translations
--- ==============================

--- Returns a translator function for the given textdomain.
--- The first returned function is for singular strings (core.translate),
--- the second for plural strings (core.translate_n).
---@param textdomain string
---@return fun(str:string, ...:any):string
---@return fun(str:string, str_plural:string, n:integer, ...:any):string
function core.get_translator(textdomain) end

--- Translates a string with the given textdomain.
---@param textdomain string
---@param str string
---@param ... any
---@return string
function core.translate(textdomain, str, ...) end

--- Translates a plural string with the given textdomain.
---@param textdomain string
---@param str string
---@param str_plural string
---@param n integer
---@param ... any
---@return string
function core.translate_n(textdomain, str, str_plural, n, ...) end

--- Resolves translations in a string for a given language code.
---@param lang_code string
---@param str string
---@return string
function core.get_translated_string(lang_code, str) end

--- ==============================
--- Aliases and registered tables
--- ==============================

core.env = {}

---@type table<string, table>
core.registered_items = {}
---@type table<string, NodeDefinition>
core.registered_nodes = {}
---@type table<string, table>
core.registered_tools = {}
---@type table<string, table>
core.registered_craftitems = {}
---@type table<string, string>
core.registered_aliases = {}
---@type table<string, EntityDefinition>
core.registered_entities = {}
---@type ABMDefinition[]
core.registered_abms = {}
---@type LBMDefinition[]
core.registered_lbms = {}
---@type table<string, OreDefinition>
core.registered_ores = {}
---@type table<string, BiomeDefinition>
core.registered_biomes = {}
---@type table<string, DecorationDefinition>
core.registered_decorations = {}
---@type table<string, ChatCommandDefinition>
core.registered_chatcommands = {}
---@type table<string, PrivilegeDefinition>
core.registered_privileges = {}

--- ==============================
--- Settings
--- ==============================

---@class Settings
core.settings = {}

--- Returns a setting value.
---@param name string
---@param default? any
---@return string|nil
function core.settings:get(name, default) end

--- Returns a boolean setting.
---@param name string
---@param default? boolean
---@return boolean|nil
function core.settings:get_bool(name, default) end

--- Returns a number setting.
---@param name string
---@param default? number
---@return number|nil
function core.settings:get_num(name, default) end

--- Returns a NoiseParams setting.
---@param name string
---@return NoiseParams|nil
function core.settings:get_np_group(name) end

--- Returns flags as a table.
---@param name string
---@return table<string,boolean>|nil
function core.settings:get_flags(name) end

--- Returns a position setting.
---@param name string
---@return vector|nil
function core.settings:get_pos(name) end

--- Sets a setting.
---@param name string
---@param value string
function core.settings:set(name, value) end

--- Sets a boolean setting.
---@param name string
---@param value boolean
function core.settings:set_bool(name, value) end

--- Sets a NoiseParams setting.
---@param name string
---@param value NoiseParams
function core.settings:set_np_group(name, value) end

--- Sets a position setting.
---@param name string
---@param value vector
function core.settings:set_pos(name, value) end

--- Removes a setting.
---@param name string
---@return boolean success
function core.settings:remove(name) end

--- Returns all setting names.
---@return string[]
function core.settings:get_names() end

--- Checks if a setting exists (ignores defaults).
---@param name string
---@return boolean
function core.settings:has(name) end

--- Writes changes to file.
---@return boolean success
function core.settings:write() end

--- Returns settings as a table.
---@return table<string, string>
function core.settings:to_table() end

--- Deprecated: use core.settings:get_pos.
function core.setting_get_pos(name) end