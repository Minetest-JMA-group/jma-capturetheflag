---@meta

--- ==============================
--- Vector
--- ==============================

--- A 3D spatial vector.
---@class vector
---@field x number
---@field y number
---@field z number
---@operator unm: vector                      -- -v
---@operator add(vector): vector              -- v1 + v2
---@operator sub(vector): vector              -- v1 - v2
---@operator mul(number): vector              -- v * s
---@operator div(number): vector              -- v / s

--- Vector manipulation library.
---@class VectorLib
vector = {}

--- Returns a new zero vector (0,0,0).
---@return vector
function vector.zero() end

--- Creates a new vector.
---@param x number|vector
---@param y? number
---@param z? number
---@return vector
function vector.new(x, y, z) end

--- Copies a vector.
---@param v vector
---@return vector
function vector.copy(v) end

--- Parses a string like "(x, y, z)".
---@param s string
---@param init? integer Starting index
---@return vector|nil, integer|nil next_pos
function vector.from_string(s, init) end

--- Converts a vector to a string "(x, y, z)".
---@param v vector
---@return string
function vector.to_string(v) end

--- Returns a unit direction vector from p1 to p2.
---@param p1 vector
---@param p2 vector
---@return vector
function vector.direction(p1, p2) end

--- Returns the Euclidean distance between two points.
---@param p1 vector
---@param p2 vector
---@return number
function vector.distance(p1, p2) end

--- Returns the length of a vector.
---@param v vector
---@return number
function vector.length(v) end

--- Returns a normalized vector (length 1).
---@param v vector
---@return vector
function vector.normalize(v) end

--- Returns a vector with each component rounded down.
---@param v vector
---@return vector
function vector.floor(v) end

--- Returns a vector with each component rounded up.
---@param v vector
---@return vector
function vector.ceil(v) end

--- Returns a vector with each component rounded to nearest integer (away from zero at 0.5).
---@param v vector
---@return vector
function vector.round(v) end

--- Returns the sign of each component.
---@param v vector
---@param tolerance? number
---@return vector
function vector.sign(v, tolerance) end

--- Returns a vector with absolute values of each component.
---@param v vector
---@return vector
function vector.abs(v) end

--- Applies a function to each component.
---@param v vector
---@param func fun(n:number):number
---@param ... any
---@return vector
function vector.apply(v, func, ...) end

--- Combines two vectors component‑wise.
---@param v vector
---@param w vector
---@param func fun(a:number, b:number):number
---@return vector
function vector.combine(v, w, func) end

--- Checks if two vectors are equal.
---@param v1 vector
---@param v2 vector
---@return boolean
function vector.equals(v1, v2) end

--- Sorts two vectors into minp and maxp.
---@param v1 vector
---@param v2 vector
---@return vector minp, vector maxp
function vector.sort(v1, v2) end

--- Returns the angle (in radians) between two vectors.
---@param v1 vector
---@param v2 vector
---@return number
function vector.angle(v1, v2) end

--- Returns the dot product.
---@param v1 vector
---@param v2 vector
---@return number
function vector.dot(v1, v2) end

--- Returns the cross product.
---@param v1 vector
---@param v2 vector
---@return vector
function vector.cross(v1, v2) end

--- Adds offsets to a vector.
---@param v vector
---@param x number
---@param y number
---@param z number
---@return vector
function vector.offset(v, x, y, z) end

--- Checks if a value is a proper vector (with metatable).
---@param v any
---@return boolean
function vector.check(v) end

--- Checks if a position is inside an axis‑aligned box (inclusive).
---@param pos vector
---@param min vector
---@param max vector
---@return boolean
function vector.in_area(pos, min, max) end

--- Returns a random integer position inside an area.
---@param min vector
---@param max vector
---@return vector
function vector.random_in_area(min, max) end

--- Returns a random unit vector.
---@return vector
function vector.random_direction() end

--- Adds a vector or scalar.
---@param v vector
---@param x vector|number
---@return vector
function vector.add(v, x) end

--- Subtracts a vector or scalar.
---@param v vector
---@param x vector|number
---@return vector
function vector.subtract(v, x) end

--- Multiplies by a scalar.
---@param v vector
---@param s number
---@return vector
function vector.multiply(v, s) end

--- Divides by a scalar.
---@param v vector
---@param s number
---@return vector
function vector.divide(v, s) end

--- Rotates a vector by a rotation vector (radians, right‑handed Z‑X‑Y).
---@param v vector
---@param r vector {pitch, yaw, roll}
---@return vector
function vector.rotate(v, r) end

--- Rotates a vector around an axis.
---@param v1 vector
---@param v2 vector
---@param a number (radians, right‑hand rule)
---@return vector
function vector.rotate_around_axis(v1, v2, a) end

--- Converts a direction vector to a rotation.
---@param direction vector
---@param up? vector (default (0,1,0))
---@return vector
function vector.dir_to_rotation(direction, up) end

--- ==============================
--- Pointed thing
--- ==============================

--- Result of pointing at a node or object.
---@class pointed_thing
---@field type "nothing"|"node"|"object"
---@field under? vector Position of the node behind the pointed face (if type="node")
---@field above? vector Position of the node in front of the pointed face (if type="node")
---@field ref? ObjectRef The pointed object (if type="object")
---@field intersection_point? vector Exact world coordinates of the intersection point (raycast only)
---@field box_id? integer ID of the pointed selection box (starting at 1) (raycast only)
---@field intersection_normal? vector Unit vector pointing outwards of the selected box (raycast only)

--- ==============================
--- ItemStack
--- ==============================

--- An item stack (C++ userdata).
---@class ItemStack
--- Returns true if the stack is empty.
---@field is_empty fun(self: ItemStack): boolean
--- Returns the item name (e.g. "default:stone").
---@field get_name fun(self: ItemStack): string
--- Sets the item name. Returns boolean indicating whether the item was cleared.
---@field set_name fun(self: ItemStack, name: string): boolean
--- Returns the number of items on the stack.
---@field get_count fun(self: ItemStack): integer
--- Sets the item count. Returns boolean indicating whether the item was cleared.
---@field set_count fun(self: ItemStack, count: integer): boolean
--- Returns tool wear (0‑65535), 0 for non‑tools.
---@field get_wear fun(self: ItemStack): integer
--- Sets tool wear. Returns boolean indicating whether the item was cleared.
---@field set_wear fun(self: ItemStack, wear: integer): boolean
--- Returns the ItemStackMetaRef for this stack.
---@field get_meta fun(self: ItemStack): ItemStackMetaRef
--- Deprecated: returns metadata string. Use get_meta():get_string("") instead.
---@field get_metadata fun(self: ItemStack): string (deprecated)
--- Deprecated: sets metadata string. Use get_meta():set_string("", str) instead.
---@field set_metadata fun(self: ItemStack, str: string): boolean (deprecated)
--- Returns the description shown in tooltips.
---@field get_description fun(self: ItemStack): string
--- Returns the short description, or nil if none.
---@field get_short_description fun(self: ItemStack): string|nil
--- Removes all items from the stack, making it empty.
---@field clear fun(self: ItemStack)
--- Replaces the contents with another item (accepts string, table, or ItemStack).
---@field replace fun(self: ItemStack, item: ItemStack|string|table)
--- Returns the stack as an itemstring.
---@field to_string fun(self: ItemStack): string
--- Returns the stack as a Lua table, or nil if empty.
---@field to_table fun(self: ItemStack): table|nil
--- Returns the maximum stack size for this item.
---@field get_stack_max fun(self: ItemStack): integer
--- Returns the number of free slots in the stack (max - count).
---@field get_free_space fun(self: ItemStack): integer
--- Returns true if the item name refers to a defined item type.
---@field is_known fun(self: ItemStack): boolean
--- Returns the item definition table.
---@field get_definition fun(self: ItemStack): table
--- Returns the tool capabilities, or those of the hand if none defined.
---@field get_tool_capabilities fun(self: ItemStack): ToolCapabilities|nil
--- Increases wear by the given amount (tools only). Valid range: 0‑65536.
---@field add_wear fun(self: ItemStack, amount: integer)
--- Increases wear so that the tool breaks after `max_uses` uses.
---@field add_wear_by_uses fun(self: ItemStack, max_uses: integer)
--- Returns the wear bar parameters, or nil if none.
---@field get_wear_bar_params fun(self: ItemStack): WearColor|nil
--- Adds another stack to this one; returns leftover.
---@field add_item fun(self: ItemStack, stack: ItemStack|string): ItemStack
--- Returns true if the given stack can be fully added.
---@field item_fits fun(self: ItemStack, stack: ItemStack|string): boolean
--- Takes (and removes) up to n items; returns taken stack.
---@field take_item fun(self: ItemStack, n?: integer): ItemStack
--- Copies up to n items (does not remove); returns copy.
---@field peek_item fun(self: ItemStack, n?: integer): ItemStack
--- Returns true if this stack is identical to another.
---@field equals fun(self: ItemStack, other: ItemStack): boolean

--- ItemStack constructor.
---@param itemstring? ItemRepresentation
---@return ItemStack
function ItemStack(itemstring) end

--- ==============================
--- VoxelArea
--- ==============================

VoxelArea = {}

--- Helper for voxel areas (inclusive coordinates).
--- Creates a VoxelArea.
---@overload fun(minp: vector, maxp: vector): VoxelArea
---@class VoxelArea
---@field MinEdge vector
---@field MaxEdge vector
---@field ystride integer
---@field zstride integer
--- Returns the index in a flat array for the given (x,y,z) (integers required).
---@field index fun(self: VoxelArea, x: integer, y: integer, z: integer): integer
--- Returns the index for a position vector.
---@field indexp fun(self: VoxelArea, pos: vector): integer
--- Returns the absolute position vector for a given index, or nil if out of bounds.
---@field position fun(self: VoxelArea, i: integer): vector|nil
--- Returns the (x,y,z) components for a given index.
---@field position fun(self: VoxelArea, i: integer): integer, integer, integer
--- Checks if (x,y,z) is inside the area.
---@field contains fun(self: VoxelArea, x: integer, y: integer, z: integer): boolean
--- Checks if a position is inside the area.
---@field containsp fun(self: VoxelArea, pos: vector): boolean
--- Checks if an index is inside the area.
---@field containsi fun(self: VoxelArea, i: integer): boolean
--- Returns an iterator over indices in a sub‑region.
---@field iter fun(self: VoxelArea, minx: integer, miny: integer, minz: integer, maxx: integer, maxy: integer, maxz: integer): function
--- Returns an iterator over indices in a sub‑region (vector version).
---@field iterp fun(self: VoxelArea, minp: vector, maxp: vector): function
--- Returns the size of the area as a vector (width, height, depth).
---@field getExtent fun(self: VoxelArea): vector
--- Returns the volume (number of nodes) of the area.
---@field getVolume fun(self: VoxelArea): integer
--- Creates a VoxelArea from a table with MinEdge and MaxEdge.
---@field new fun(self: VoxelArea, tbl: {MinEdge:vector, MaxEdge:vector}): VoxelArea

--- ==============================
--- VoxelManip
--- ==============================

--- Low‑level, fast map access.
---@class VoxelManip
--- Loads a region into the VoxelManip; returns actual emerged pmin, pmax.
---@field read_from_map fun(self: VoxelManip, p1?: vector, p2?: vector): vector emerged_min, vector emerged_max
--- Clears and resizes the VoxelManip to the given region (no map read). Optionally fills with node.
---@field initialize fun(self: VoxelManip, p1: vector, p2: vector, node?: {name:string, param1?:integer, param2?:integer}): vector, vector
--- Writes the data back to the map. If light is true (default), recalculates lighting.
---@field write_to_map fun(self: VoxelManip, light?: boolean)
--- Returns the node content data as an array of content IDs. Optionally fills a buffer table.
---@field get_data fun(self: VoxelManip, buffer?: table): table
--- Sets the node content data.
---@field set_data fun(self: VoxelManip, data: table)
--- Returns the light data (param1) as an array of integers 0‑255. Optionally fills a buffer.
---@field get_light_data fun(self: VoxelManip, buffer?: table): table
--- Sets the light data.
---@field set_light_data fun(self: VoxelManip, light_data: table)
--- Returns the param2 data as an array of integers 0‑255. Optionally fills a buffer.
---@field get_param2_data fun(self: VoxelManip, buffer?: table): table
--- Sets the param2 data.
---@field set_param2_data fun(self: VoxelManip, param2_data: table)
--- Calculates lighting within the VoxelManip (mapgen only). Optionally limits area and shadow propagation.
---@field calc_lighting fun(self: VoxelManip, p1?: vector, p2?: vector, propagate_shadow?: boolean)
--- Sets lighting to a uniform value (mapgen only). Optionally limits area.
---@field set_lighting fun(self: VoxelManip, light: {day:integer, night:integer}, p1?: vector, p2?: vector)
--- Returns the current lighting (mapgen only). Optionally limits area.
---@field get_lighting fun(self: VoxelManip, p1?: vector, p2?: vector): {day:integer, night:integer}
--- Updates liquid flow.
---@field update_liquids fun(self: VoxelManip)
--- Returns true if the data has been modified since last read from map (mapgen only).
---@field was_modified fun(self: VoxelManip): boolean
--- Returns the actual emerged minimum and maximum positions.
---@field get_emerged_area fun(self: VoxelManip): vector, vector
--- Frees the internal data buffers (recommended to avoid memory leaks).
---@field close fun(self: VoxelManip)

--- Creates a VoxelManip (optionally loads area).
---@param pos1? vector
---@param pos2? vector
---@return VoxelManip
function VoxelManip(pos1, pos2) end

--- ==============================
--- PseudoRandom
--- ==============================

--- 16‑bit pseudorandom generator (K&R LCG).
---@class PseudoRandom
--- Returns the next random integer. If min/max given, returns in range [min,max].
---@field next fun(self: PseudoRandom, min?: integer, max?: integer): integer
--- Returns the current generator state as a number (can be used as seed to reconstruct).
---@field get_state fun(self: PseudoRandom): integer

---@param seed integer
---@return PseudoRandom
function PseudoRandom(seed) end

--- ==============================
--- PcgRandom
--- ==============================

--- 32‑bit pseudorandom generator (PCG32).
---@class PcgRandom
--- Returns the next random integer. If min/max given, returns in range [min,max].
---@field next fun(self: PcgRandom, min?: integer, max?: integer): integer
--- Returns a normally distributed random integer in [min,max] (approximate).
---@field rand_normal_dist fun(self: PcgRandom, min: integer, max: integer, num_trials?: integer): integer
--- Returns the generator state encoded as a string.
---@field get_state fun(self: PcgRandom): string
--- Restores generator state from a previously obtained string.
---@field set_state fun(self: PcgRandom, state: string)

---@param seed integer 64‑bit unsigned
---@param seq? integer 64‑bit unsigned sequence
---@return PcgRandom
function PcgRandom(seed, seq) end

--- ==============================
--- SecureRandom
--- ==============================

--- OS‑provided cryptographically secure PRNG.
---@class SecureRandom
--- Returns `count` random bytes as a string (default 1, max 2048).
---@field next_bytes fun(self: SecureRandom, count?: integer): string

---@return SecureRandom
function SecureRandom() end

--- ==============================
--- Raycast
--- ==============================

--- Raycast iterator.
---@class Raycast
--- Returns the next pointed thing, or nil when done.
---@field next fun(self: Raycast): pointed_thing|nil

--- Creates a raycast.
---@param pos1 vector
---@param pos2 vector
---@param objects? boolean (default true)
---@param liquids? boolean (default false)
---@param pointabilities? Pointabilities
---@return Raycast
function Raycast(pos1, pos2, objects, liquids, pointabilities) end

--- ==============================
--- NodeTimerRef
--- ==============================

--- Per‑node timer.
---@class NodeTimerRef
--- Sets the timer state (timeout and elapsed in seconds).
---@field set fun(self: NodeTimerRef, timeout: number, elapsed: number)
--- Starts the timer with the given timeout (elapsed = 0).
---@field start fun(self: NodeTimerRef, timeout: number)
--- Stops the timer.
---@field stop fun(self: NodeTimerRef)
--- Returns the current timeout in seconds (0 if inactive).
---@field get_timeout fun(self: NodeTimerRef): number
--- Returns the current elapsed time in seconds.
---@field get_elapsed fun(self: NodeTimerRef): number
--- Returns true if the timer is started.
---@field is_started fun(self: NodeTimerRef): boolean

--- ==============================
--- AreaStore
--- ==============================

--- Spatial index for 3D cuboids.
---@class AreaStore
--- Returns area information for the given ID. Optionally include corners and data.
---@field get_area fun(self: AreaStore, id: integer, include_corners?: boolean, include_data?: boolean): table|nil
--- Returns all areas containing the given position, indexed by ID.
---@field get_areas_for_pos fun(self: AreaStore, pos: vector, include_corners?: boolean, include_data?: boolean): table<integer, table>
--- Returns all areas intersecting the specified cuboid.
---@field get_areas_in_area fun(self: AreaStore, corner1: vector, corner2: vector, accept_overlap?: boolean, include_corners?: boolean, include_data?: boolean): table<integer, table>
--- Inserts a new area; returns the new ID, or nil on failure.
---@field insert_area fun(self: AreaStore, corner1: vector, corner2: vector, data?: string, id?: integer): integer|nil
--- Reserves space for `count` areas (LibSpatial only).
---@field reserve fun(self: AreaStore, count: integer)
--- Removes the area with the given ID; returns success.
---@field remove_area fun(self: AreaStore, id: integer): boolean
--- Sets cache parameters for the prefiltering cache.
---@field set_cache_params fun(self: AreaStore, params: {enabled?:boolean, block_radius?:integer, limit?:integer})
--- Serializes the area store to a binary string.
---@field to_string fun(self: AreaStore): string
--- Writes the serialized data to a file.
---@field to_file fun(self: AreaStore, filename: string)
--- Deserializes a binary string into the area store.
---@field from_string fun(self: AreaStore, str: string): boolean, string? err
--- Reads serialized data from a file.
---@field from_file fun(self: AreaStore, filename: string): boolean, string? err

---@param type_name? "LibSpatial" (default)
---@return AreaStore
function AreaStore(type_name) end

--- ==============================
--- ModChannel
--- ==============================

--- Communication channel between server and client mods.
---@class ModChannel
--- Leaves the channel; further sends will fail.
---@field leave fun(self: ModChannel)
--- Returns true if the channel is writeable.
---@field is_writeable fun(self: ModChannel): boolean
--- Sends a message to all subscribers (max length 65535).
---@field send_all fun(self: ModChannel, message: string)

--- ==============================
--- AsyncJob
--- ==============================

--- Reference to an async job.
---@class AsyncJob
--- Attempts to cancel the job; returns true if cancelled (job not started).
---@field cancel fun(self: AsyncJob): boolean

--- ==============================
--- ValueNoise
--- ==============================

--- Value noise generator.
---@class ValueNoise
--- Returns 2D noise value at (x,y).
---@field get_2d fun(self: ValueNoise, pos: {x:number, y:number}): number
--- Returns 3D noise value at (x,y,z).
---@field get_3d fun(self: ValueNoise, pos: vector): number

---@param noiseparams NoiseParams
---@return ValueNoise
function ValueNoise(noiseparams) end
---@deprecated
---@param seed integer
---@param octaves integer
---@param persistence number
---@param spread number|vector
---@return ValueNoise
function ValueNoise(seed, octaves, persistence, spread) end

--- ==============================
--- ValueNoiseMap
--- ==============================

--- Bulk value noise generator.
---@class ValueNoiseMap
--- Returns a 2D array of noise values starting at pos.
---@field get_2d_map fun(self: ValueNoiseMap, pos: {x:number, y:number}): number[][]
--- Returns a 3D array of noise values starting at pos.
---@field get_3d_map fun(self: ValueNoiseMap, pos: vector): number[][][]
--- Returns a flat array of 2D noise values.
---@field get_2d_map_flat fun(self: ValueNoiseMap, pos: {x:number, y:number}, buffer?: table): table
--- Returns a flat array of 3D noise values.
---@field get_3d_map_flat fun(self: ValueNoiseMap, pos: vector, buffer?: table): table
--- Calculates a 2D map and stores internally.
---@field calc_2d_map fun(self: ValueNoiseMap, pos: {x:number, y:number})
--- Calculates a 3D map and stores internally.
---@field calc_3d_map fun(self: ValueNoiseMap, pos: vector)
--- Returns a slice of the last computed map.
---@field get_map_slice fun(self: ValueNoiseMap, slice_offset: {x?:integer, y?:integer, z?:integer}, slice_size: {x?:integer, y?:integer, z?:integer}, buffer?: table): table

---@param noiseparams NoiseParams
---@param size {x:integer, y:integer, z?:integer}
---@return ValueNoiseMap|nil
function ValueNoiseMap(noiseparams, size) end
---@deprecated
---@param noiseparams NoiseParams
---@param size {x:integer, y:integer, z?:integer}
---@return ValueNoiseMap|nil
function ValueNoiseMap(noiseparams, size) end

--- ==============================
--- ObjectRef hierarchy
--- ==============================

--- Base object (common methods for all objects).
---@class ObjectRef
--- Returns true if the object is still valid.
---@field is_valid fun(self: ObjectRef): boolean
--- Removes the object (entities only, no‑op for players).
---@field remove fun(self: ObjectRef)
--- Returns the position, or nil if invalid.
---@field get_pos fun(self: ObjectRef): vector|nil
--- Sets the position (no‑op if attached).
---@field set_pos fun(self: ObjectRef, pos: vector)
--- Adds to the current position (no‑op if attached).
---@field add_pos fun(self: ObjectRef, pos: vector)
--- Smoothly moves to a position (for entities; for players same as set_pos).
---@field move_to fun(self: ObjectRef, pos: vector, continuous?: boolean)
--- Returns the velocity vector.
---@field get_velocity fun(self: ObjectRef): vector
--- Adds to the current velocity.
---@field add_velocity fun(self: ObjectRef, vel: vector)
--- Punches the object.
---@field punch fun(self: ObjectRef, puncher: ObjectRef|nil, time_from_last_punch?: number, tool_capabilities?: ToolCapabilities, dir?: vector)
--- Simulates a right‑click.
---@field right_click fun(self: ObjectRef, clicker: PlayerRef|LuaEntityRef)
--- Sets health points (0‑65535). For players, also clamped by hp_max.
---@field set_hp fun(self: ObjectRef, hp: integer, reason?: PlayerHPChangeReason)
--- Returns current health points.
---@field get_hp fun(self: ObjectRef): integer
--- Returns the inventory reference, or nil if none.
---@field get_inventory fun(self: ObjectRef): InvRef|nil
--- Returns the name of the wield list.
---@field get_wield_list fun(self: ObjectRef): string
--- Returns the index of the wielded item (starting at 1).
---@field get_wield_index fun(self: ObjectRef): integer
--- Returns a copy of the wielded item.
---@field get_wielded_item fun(self: ObjectRef): ItemStack
--- Sets the wielded item; returns true if successful.
---@field set_wielded_item fun(self: ObjectRef, item: ItemStack|string): boolean
--- Sets armor groups (replaces all).
---@field set_armor_groups fun(self: ObjectRef, groups: table<string, integer>)
--- Returns the current armor groups.
---@field get_armor_groups fun(self: ObjectRef): table<string, integer>
--- Sets the animation (entities only).
---@field set_animation fun(self: ObjectRef, frame_range: {x:number, y:number}, frame_speed?: number, frame_blend?: number, frame_loop?: boolean)
--- Sets only the frame speed without restarting animation.
---@field set_animation_frame_speed fun(self: ObjectRef, frame_speed: number)
--- Returns the current animation parameters.
---@field get_animation fun(self: ObjectRef): {frame_range:{x:number,y:number}, frame_speed:number, frame_blend:number, frame_loop:boolean}
--- Deprecated: use set_bone_override.
---@field set_bone_position fun(self: ObjectRef, bone: string, pos: vector, rot: vector) (deprecated)
--- Deprecated: use get_bone_override.
---@field get_bone_position fun(self: ObjectRef, bone: string): vector, vector (deprecated)
--- Sets a bone override.
---@field set_bone_override fun(self: ObjectRef, bone: string, override: table|nil)
--- Returns a bone override.
---@field get_bone_override fun(self: ObjectRef, bone: string): table
--- Returns all bone overrides.
---@field get_bone_overrides fun(self: ObjectRef): table<string, table>
--- Attaches this object to a parent.
---@field set_attach fun(self: ObjectRef, parent: PlayerRef|LuaEntityRef, bone?: string, pos?: vector, rot?: vector, forced_visible?: boolean)
--- Detaches from parent.
---@field set_detach fun(self: ObjectRef)
--- Returns attachment info, or nil if not attached.
---@field get_attach fun(self: ObjectRef): (ObjectRef|nil, string|nil, vector|nil, vector|nil, boolean|nil)
--- Returns a list of attached child objects.
---@field get_children fun(self: ObjectRef): ObjectRef[]
--- Sets object properties.
---@field set_properties fun(self: ObjectRef, props: table)
--- Returns object properties.
---@field get_properties fun(self: ObjectRef): table
--- Sets the set of players who can see this object (managed observers).
---@field set_observers fun(self: ObjectRef, observers: table<string, true>|nil)
--- Returns the observer set, or nil if unmanaged.
---@field get_observers fun(self: ObjectRef): table<string, true>|nil
--- Returns the effective observers (taking attachments into account).
---@field get_effective_observers fun(self: ObjectRef): table<string, true>
--- Returns the luaentity table, or nil if not a Lua entity.
---@field get_luaentity fun(self: ObjectRef): table|nil
--- Deprecated: use get_luaentity().name.
---@field get_entity_name fun(self: ObjectRef): string (deprecated)
--- Returns true if the object is a player.
---@field is_player fun(self: ObjectRef): boolean
--- Returns the nametag attributes.
---@field get_nametag_attributes fun(self: ObjectRef): {text:string, color:{a:integer,r:integer,g:integer,b:integer}, bgcolor:{a:integer,r:integer,g:integer,b:integer}}
--- Sets the nametag attributes.
---@field set_nametag_attributes fun(self: ObjectRef, attr: {text?:string, color?:ColorSpec, bgcolor?:ColorSpec|false})
--- Returns a globally unique identifier (string).
---@field get_guid fun(self: ObjectRef): string

--- Player object.
---@class PlayerRef : ObjectRef
--- Returns the player position
---@field get_pos fun(self: ObjectRef): vector
--- Returns the inventory reference (always exists for players).
---@field get_inventory fun(self: PlayerRef): InvRef
--- Returns the player metadata (always exists).
---@field get_meta fun(self: PlayerRef): PlayerMetaRef
--- Returns the player name.
---@field get_player_name fun(self: PlayerRef): string
--- Deprecated: use get_velocity.
---@field get_player_velocity fun(self: PlayerRef): vector (deprecated)
--- Deprecated: use add_velocity.
---@field add_player_velocity fun(self: PlayerRef, vel: vector) (deprecated)
--- Returns the look direction as a unit vector.
---@field get_look_dir fun(self: PlayerRef): vector
--- Returns the horizontal look angle (yaw) in radians.
---@field get_look_horizontal fun(self: PlayerRef): number
--- Returns the vertical look angle (pitch) in radians.
---@field get_look_vertical fun(self: PlayerRef): number
--- Sets the horizontal look angle.
---@field set_look_horizontal fun(self: PlayerRef, rad: number)
--- Sets the vertical look angle.
---@field set_look_vertical fun(self: PlayerRef, rad: number)
--- Deprecated: use get_look_vertical.
---@field get_look_pitch fun(self: PlayerRef): number (deprecated)
--- Deprecated: use get_look_horizontal.
---@field get_look_yaw fun(self: PlayerRef): number (deprecated)
--- Deprecated: use set_look_vertical.
---@field set_look_pitch fun(self: PlayerRef, rad: number) (deprecated)
--- Deprecated: use set_look_horizontal.
---@field set_look_yaw fun(self: PlayerRef, rad: number) (deprecated)
--- Returns the player's breath (0‑max).
---@field get_breath fun(self: PlayerRef): integer
--- Sets the player's breath.
---@field set_breath fun(self: PlayerRef, breath: integer)
--- Sets the field of view override.
---@field set_fov fun(self: PlayerRef, fov: number, is_multiplier?: boolean, transition_time?: number)
--- Returns the FOV override and transition time.
---@field get_fov fun(self: PlayerRef): number, boolean, number
--- Deprecated: use get_meta.
---@field set_attribute fun(self: PlayerRef, attr: string, value: string|nil) (deprecated)
--- Deprecated: use get_meta.
---@field get_attribute fun(self: PlayerRef, attr: string): string|nil (deprecated)
--- Returns the player metadata.
---@field get_meta fun(self: PlayerRef): PlayerMetaRef
--- Sets the inventory formspec.
---@field set_inventory_formspec fun(self: PlayerRef, formspec: string)
--- Returns the current inventory formspec.
---@field get_inventory_formspec fun(self: PlayerRef): string
--- Sets a formspec string to be prepended to all formspecs shown to this player.
---@field set_formspec_prepend fun(self: PlayerRef, formspec: string)
--- Returns the current formspec prepend string.
---@field get_formspec_prepend fun(self: PlayerRef): string
--- Returns the current player controls (key states and movement values).
---@field get_player_control fun(self: PlayerRef): {up:boolean, down:boolean, left:boolean, right:boolean, jump:boolean, sneak:boolean, aux1:boolean, zoom:boolean, dig:boolean, place:boolean, LMB:boolean, RMB:boolean, movement_x:number, movement_y:number}
--- Returns the control bits as an integer.
---@field get_player_control_bits fun(self: PlayerRef): integer
--- Overrides physics attributes.
---@field set_physics_override fun(self: PlayerRef, override: table)
--- Returns the current physics override table.
---@field get_physics_override fun(self: PlayerRef): table
--- Adds a HUD element; returns its ID.
---@field hud_add fun(self: PlayerRef, def: HUDDefinition): integer
--- Removes a HUD element by ID.
---@field hud_remove fun(self: PlayerRef, id: integer)
--- Changes a property of an existing HUD element.
---@field hud_change fun(self: PlayerRef, id: integer, stat: string, value: any)
--- Returns the definition of a HUD element, or nil.
---@field hud_get fun(self: PlayerRef, id: integer): HUDDefinition|nil
--- Returns a table of all HUD elements for this player.
---@field hud_get_all fun(self: PlayerRef): table<integer, HUDDefinition>
--- Sets HUD flags (hotbar, healthbar, etc.).
---@field hud_set_flags fun(self: PlayerRef, flags: table<string, boolean>)
--- Returns the current HUD flags.
---@field hud_get_flags fun(self: PlayerRef): table<string, boolean>
--- Sets the number of items in the hotbar (1‑32).
---@field hud_set_hotbar_itemcount fun(self: PlayerRef, count: integer)
--- Returns the number of visible hotbar items.
---@field hud_get_hotbar_itemcount fun(self: PlayerRef): integer
--- Sets the hotbar background image.
---@field hud_set_hotbar_image fun(self: PlayerRef, texture: string)
--- Returns the hotbar background image.
---@field hud_get_hotbar_image fun(self: PlayerRef): string
--- Sets the hotbar selected item image.
---@field hud_set_hotbar_selected_image fun(self: PlayerRef, texture: string)
--- Returns the hotbar selected item image.
---@field hud_get_hotbar_selected_image fun(self: PlayerRef): string
--- Overrides the minimap modes and selects one.
---@field set_minimap_modes fun(self: PlayerRef, modes: table[], selected: integer)
--- Sets sky parameters (new style).
---@field set_sky fun(self: PlayerRef, params: table)
--- Sets sky parameters (deprecated style).
---@field set_sky fun(self: PlayerRef, base_color: ColorSpec, type: string, textures: string[], clouds: boolean) (deprecated)
--- Returns sky parameters (if as_table true) or legacy values.
---@field get_sky fun(self: PlayerRef, as_table: true): table
---@field get_sky fun(self: PlayerRef): string, string, string[], boolean (deprecated)
--- Deprecated: use get_sky(true).
---@field get_sky_color fun(self: PlayerRef): table (deprecated)
--- Sets sun parameters.
---@field set_sun fun(self: PlayerRef, params: table)
--- Returns sun parameters.
---@field get_sun fun(self: PlayerRef): table
--- Sets moon parameters.
---@field set_moon fun(self: PlayerRef, params: table)
--- Returns moon parameters.
---@field get_moon fun(self: PlayerRef): table
--- Sets stars parameters.
---@field set_stars fun(self: PlayerRef, params: table)
--- Returns stars parameters.
---@field get_stars fun(self: PlayerRef): table
--- Sets cloud parameters.
---@field set_clouds fun(self: PlayerRef, params: table)
--- Returns cloud parameters.
---@field get_clouds fun(self: PlayerRef): table
--- Overrides day/night ratio (0‑1). Pass nil to disable override.
---@field override_day_night_ratio fun(self: PlayerRef, ratio: number|nil)
--- Returns the current day/night ratio override, or nil if not overridden.
---@field get_day_night_ratio fun(self: PlayerRef): number|nil
--- Sets local player animations (third‑person).
---@field set_local_animation fun(self: PlayerRef, idle: {x:number,y:number}, walk: {x:number,y:number}, dig: {x:number,y:number}, walk_while_dig: {x:number,y:number}, frame_speed?: number)
--- Returns local animation parameters.
---@field get_local_animation fun(self: PlayerRef): {x:number,y:number}, {x:number,y:number}, {x:number,y:number}, {x:number,y:number}, number
--- Sets camera offset vectors.
---@field set_eye_offset fun(self: PlayerRef, firstperson?: vector, thirdperson_back?: vector, thirdperson_front?: vector)
--- Returns camera offset vectors.
---@field get_eye_offset fun(self: PlayerRef): vector, vector, vector
--- Sets camera mode.
---@field set_camera fun(self: PlayerRef, params: {mode:"any"|"first"|"third"|"third_front"})
--- Returns current camera parameters.
---@field get_camera fun(self: PlayerRef): {mode:string}
--- Sends a mapblock to the player immediately.
---@field send_mapblock fun(self: PlayerRef, blockpos: vector): boolean
--- Sets lighting parameters (saturation, shadows, exposure, bloom, volumetric light).
---@field set_lighting fun(self: PlayerRef, lighting: table)
--- Returns current lighting parameters.
---@field get_lighting fun(self: PlayerRef): table
--- Respawns the player (same as death screen).
---@field respawn fun(self: PlayerRef)
--- Returns player flags (breathing, drowning, node_damage).
---@field get_flags fun(self: PlayerRef): {breathing:boolean, drowning:boolean, node_damage:boolean}
--- Sets player flags.
---@field set_flags fun(self: PlayerRef, flags: table)

--- Lua entity object.
---@class LuaEntityRef : ObjectRef
--- Sets velocity (entities only).
---@field set_velocity fun(self: LuaEntityRef, vel: vector)
--- Sets acceleration (entities only).
---@field set_acceleration fun(self: LuaEntityRef, acc: vector)
--- Returns acceleration (entities only).
---@field get_acceleration fun(self: LuaEntityRef): vector
--- Sets rotation (radians, right‑handed Z‑X‑Y) (entities only).
---@field set_rotation fun(self: LuaEntityRef, rot: vector)
--- Returns rotation (entities only).
---@field get_rotation fun(self: LuaEntityRef): vector
--- Sets yaw (heading) in radians; resets pitch and roll to 0 (entities only).
---@field set_yaw fun(self: LuaEntityRef, yaw: number)
--- Returns yaw (entities only).
---@field get_yaw fun(self: LuaEntityRef): number
--- Sets a texture modifier (entities only).
---@field set_texture_mod fun(self: LuaEntityRef, mod: string)
--- Returns the current texture modifier (entities only).
---@field get_texture_mod fun(self: LuaEntityRef): string
--- Sets a sprite animation (entities with sprite visual).
---@field set_sprite fun(self: LuaEntityRef, start_frame: {x:integer, y:integer}, num_frames: integer, framelength: number, select_x_by_camera?: boolean)
--- Returns the luaentity table, or nil.
---@field get_luaentity fun(self: LuaEntityRef): table|nil
--- Deprecated: use get_luaentity().name.
---@field get_entity_name fun(self: LuaEntityRef): string (deprecated)

--- Item entity object (same as LuaEntityRef).
---@class ItemEntityRef : LuaEntityRef
-- (no additional unique methods)

--- ==============================
--- Metadata classes
--- ==============================

--- Base metadata.
---@class MetaData
--- Returns true if the key exists, false if not, nil if metadata is invalid.
---@field contains fun(self: MetaData, key: string): boolean|nil
--- Returns the string value for the key, or nil if not present.
---@field get fun(self: MetaData, key: string): string|nil
--- Returns the string value, or "" if not present.
---@field get_string fun(self: MetaData, key: string): string
--- Returns the integer value, or 0 if not present.
---@field get_int fun(self: MetaData, key: string): integer
--- Returns the float value, or 0 if not present.
---@field get_float fun(self: MetaData, key: string): number
--- Sets a string value. Passing "" deletes the key.
---@field set_string fun(self: MetaData, key: string, value: string)
--- Sets an integer value (stored as string).
---@field set_int fun(self: MetaData, key: string, value: integer)
--- Sets a float value (stored as string).
---@field set_float fun(self: MetaData, key: string, value: number)
--- Returns a list of all keys.
---@field get_keys fun(self: MetaData): string[]
--- Returns a metadata table (fields and optionally inventory) or nil on failure.
---@field to_table fun(self: MetaData): table|nil
--- Imports metadata from a table; returns true on success.
---@field from_table fun(self: MetaData, tbl: table): boolean
--- Returns true if this metadata has the same key‑value pairs as another.
---@field equals fun(self: MetaData, other: MetaData): boolean

--- Node metadata.
---@class NodeMetaRef : MetaData
--- Returns the inventory reference for this node.
---@field get_inventory fun(self: NodeMetaRef): InvRef
--- Marks specific keys as private (not sent to client).
---@field mark_as_private fun(self: NodeMetaRef, name: string|string[])

--- ItemStack metadata.
---@class ItemStackMetaRef : MetaData
--- Overrides the tool capabilities for this stack. Pass nil to clear.
---@field set_tool_capabilities fun(self: ItemStackMetaRef, caps: ToolCapabilities|nil)
--- Overrides the wear bar parameters. Pass nil to clear.
---@field set_wear_bar_params fun(self: ItemStackMetaRef, params: WearColor|nil)

--- Player metadata.
---@class PlayerMetaRef : MetaData

--- Mod storage.
---@class ModStorage : MetaData
--- Reloads the storage from disk.
---@field reload fun(self: ModStorage)

--- ==============================
--- InvRef
--- ==============================

--- Inventory reference.
---@class InvRef
--- Returns true if the list is empty.
---@field is_empty fun(self: InvRef, listname: string): boolean
--- Returns the size of the list.
---@field get_size fun(self: InvRef, listname: string): integer
--- Sets the size of the list (creates if needed). Returns false on error.
---@field set_size fun(self: InvRef, listname: string, size: integer): boolean
--- Returns the width of the list (used for crafting).
---@field get_width fun(self: InvRef, listname: string): integer
--- Sets the width of the list. Returns false on error.
---@field set_width fun(self: InvRef, listname: string, width: integer): boolean
--- Returns a copy of the stack at index i (1‑based).
---@field get_stack fun(self: InvRef, listname: string, i: integer): ItemStack
--- Sets the stack at index i.
---@field set_stack fun(self: InvRef, listname: string, i: integer, stack: ItemStack)
--- Returns the whole list as an array of ItemStacks, or nil if list doesn't exist.
---@field get_list fun(self: InvRef, listname: string): ItemStack[]|nil
--- Sets the whole list (size remains unchanged).
---@field set_list fun(self: InvRef, listname: string, list: ItemStack[])
--- Returns a table mapping list names to item arrays.
---@field get_lists fun(self: InvRef): table<string, ItemStack[]>
--- Sets multiple lists at once (sizes remain unchanged).
---@field set_lists fun(self: InvRef, lists: table<string, ItemStack[]>)
--- Adds a stack to the list; returns leftover.
---@field add_item fun(self: InvRef, listname: string, stack: ItemRepresentation): ItemStack
--- Returns true if the stack can be fully added.
---@field room_for_item fun(self: InvRef, listname: string, stack: ItemRepresentation): boolean
--- Returns true if the list contains the given stack (ignores wear, optionally matches meta).
---@field contains_item fun(self: InvRef, listname: string, stack: ItemRepresentation, match_meta?: boolean): boolean
--- Removes as many items as possible; returns the stack actually removed.
---@field remove_item fun(self: InvRef, listname: string, stack: ItemRepresentation, match_meta?: boolean): ItemStack
--- Returns the location of this inventory as a table (type, name/pos).
---@field get_location fun(self: InvRef): {type: string}

--- ==============================
--- HUDDefinition
--- ==============================

---@class HUDDefinition
---@field type "compass"|"hotbar"|"image"|"image_waypoint"|"inventory"|"minimap"|"statbar"|"text"|"waypoint"
---@field hud_elem_type? string (deprecated)
---@field position? {x:number, y:number}
---@field name? string
---@field scale? {x:number, y:number}
---@field text? string
---@field text2? string
---@field number? integer
---@field item? integer
---@field direction? integer
---@field alignment? {x:number, y:number}
---@field offset? {x:number, y:number}
---@field world_pos? vector
---@field size? {x:number, y:number}
---@field z_index? integer
---@field style? integer

--- ==============================
--- dump
--- ==============================

--- Returns a human‑readable string representation of a value.
---@param value any
---@param dumped? table (for internal circular reference tracking)
---@return string
function dump(value, dumped) end