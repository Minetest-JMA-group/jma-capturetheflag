---@meta

--- Vector type (a table with x, y, z fields).
---@class vector
---@field x number
---@field y number
---@field z number

--- Pointed thing – result of pointing at a node or object.
---@class pointed_thing
---@field type "nothing"|"node"|"object"
---@field under? vector Position of the node behind the pointed face (if type="node")
---@field above? vector Position of the node in front of the pointed face (if type="node")
---@field ref? ObjectRef The pointed object (if type="object")
---@field intersection_point? vector Exact world coordinates of the intersection point (raycast only)
---@field box_id? integer ID of the pointed selection box (starting at 1) (raycast only)
---@field intersection_normal? vector Unit vector pointing outwards of the selected box (raycast only)

--- Vector manipulation library.
---@class VectorLib
vector = {}

---@return vector
function vector.zero() end

--- Create a vector.
---@param x number|vector
---@param y? number
---@param z? number
---@return vector
function vector.new(x, y, z) end

--- Copy a vector.
---@param v vector
---@return vector
function vector.copy(v) end

--- Parse a string like "(x, y, z)".
---@param s string
---@param init? integer Starting index
---@return vector|nil, integer|nil next_pos
function vector.from_string(s, init) end

--- Convert to string "(x, y, z)".
---@param v vector
---@return string
function vector.to_string(v) end

--- Get a unit direction vector from p1 to p2.
---@param p1 vector
---@param p2 vector
---@return vector
function vector.direction(p1, p2) end

--- Get distance between two points.
---@param p1 vector
---@param p2 vector
---@return number
function vector.distance(p1, p2) end

--- Get length of vector.
---@param v vector
---@return number
function vector.length(v) end

--- Normalize a vector.
---@param v vector
---@return vector
function vector.normalize(v) end

--- Floor each component.
---@param v vector
---@return vector
function vector.floor(v) end

--- Ceil each component.
---@param v vector
---@return vector
function vector.ceil(v) end

--- Round each component (away from zero at 0.5).
---@param v vector
---@return vector
function vector.round(v) end

--- Sign of each component.
---@param v vector
---@param tolerance? number
---@return vector
function vector.sign(v, tolerance) end

--- Absolute value of each component.
---@param v vector
---@return vector
function vector.abs(v) end

--- Apply a function to each component.
---@param v vector
---@param func fun(n:number):number
---@param ... any Arguments to func
---@return vector
function vector.apply(v, func, ...) end

--- Combine two vectors component‑wise.
---@param v vector
---@param w vector
---@param func fun(a:number, b:number):number
---@return vector
function vector.combine(v, w, func) end

--- Check equality.
---@param v1 vector
---@param v2 vector
---@return boolean
function vector.equals(v1, v2) end

--- Sort two vectors into minp, maxp.
---@param v1 vector
---@param v2 vector
---@return vector minp, vector maxp
function vector.sort(v1, v2) end

--- Angle between two vectors (radians).
---@param v1 vector
---@param v2 vector
---@return number
function vector.angle(v1, v2) end

--- Dot product.
---@param v1 vector
---@param v2 vector
---@return number
function vector.dot(v1, v2) end

--- Cross product.
---@param v1 vector
---@param v2 vector
---@return vector
function vector.cross(v1, v2) end

--- Add offsets.
---@param v vector
---@param x number
---@param y number
---@param z number
---@return vector
function vector.offset(v, x, y, z) end

--- Check if a value is a proper vector (with metatable).
---@param v any
---@return boolean
function vector.check(v) end

--- Check if a position is inside an axis‑aligned box (inclusive).
---@param pos vector
---@param min vector
---@param max vector
---@return boolean
function vector.in_area(pos, min, max) end

--- Get a random integer position inside an area.
---@param min vector
---@param max vector
---@return vector
function vector.random_in_area(min, max) end

--- Get a random unit vector.
---@return vector
function vector.random_direction() end

--- Add a vector or scalar.
---@param v vector
---@param x vector|number
---@return vector
function vector.add(v, x) end

--- Subtract a vector or scalar.
---@param v vector
---@param x vector|number
---@return vector
function vector.subtract(v, x) end

--- Multiply by scalar.
---@param v vector
---@param s number
---@return vector
function vector.multiply(v, s) end

--- Divide by scalar.
---@param v vector
---@param s number
---@return vector
function vector.divide(v, s) end

--- Rotate a vector by a rotation vector (radians, right‑handed Z‑X‑Y).
---@param v vector
---@param r vector {pitch, yaw, roll}
---@return vector
function vector.rotate(v, r) end

--- Rotate a vector around an axis.
---@param v1 vector
---@param v2 vector Axis
---@param a number Angle (radians, right‑hand rule)
---@return vector
function vector.rotate_around_axis(v1, v2, a) end

--- Convert direction to rotation.
---@param direction vector
---@param up? vector Up vector (defaults to (0,1,0))
---@return vector rotation
function vector.dir_to_rotation(direction, up) end

--- ItemStack userdata.
---@class ItemStack
---@field is_empty fun(self: ItemStack): boolean
---@field get_name fun(self: ItemStack): string
---@field set_name fun(self: ItemStack, name: string): boolean
---@field get_count fun(self: ItemStack): integer
---@field set_count fun(self: ItemStack, count: integer): boolean
---@field get_wear fun(self: ItemStack): integer
---@field set_wear fun(self: ItemStack, wear: integer): boolean
---@field get_meta fun(self: ItemStack): ItemStackMetaRef
---@field get_metadata fun(self: ItemStack): string (deprecated)
---@field set_metadata fun(self: ItemStack, str: string): boolean (deprecated)
---@field get_description fun(self: ItemStack): string
---@field get_short_description fun(self: ItemStack): string|nil
---@field clear fun(self: ItemStack)
---@field replace fun(self: ItemStack, item: ItemStack|string|table)
---@field to_string fun(self: ItemStack): string
---@field to_table fun(self: ItemStack): table|nil
---@field get_stack_max fun(self: ItemStack): integer
---@field get_free_space fun(self: ItemStack): integer
---@field is_known fun(self: ItemStack): boolean
---@field get_definition fun(self: ItemStack): table
---@field get_tool_capabilities fun(self: ItemStack): table|nil
---@field add_wear fun(self: ItemStack, amount: integer)
---@field add_wear_by_uses fun(self: ItemStack, max_uses: integer)
---@field get_wear_bar_params fun(self: ItemStack): table|nil
---@field add_item fun(self: ItemStack, stack: ItemStack|string): ItemStack
---@field item_fits fun(self: ItemStack, stack: ItemStack|string): boolean
---@field take_item fun(self: ItemStack, n?: integer): ItemStack
---@field peek_item fun(self: ItemStack, n?: integer): ItemStack
---@field equals fun(self: ItemStack, other: ItemStack): boolean

--- Constructor for ItemStack.
---@param itemstring? string|table|ItemStack
---@return ItemStack
function ItemStack(itemstring) end

--- VoxelArea userdata.
---@class VoxelArea
---@field MinEdge vector
---@field MaxEdge vector
---@field ystride integer
---@field zstride integer
---@field index fun(self: VoxelArea, x: integer, y: integer, z: integer): integer
---@field indexp fun(self: VoxelArea, pos: vector): integer
---@field position fun(self: VoxelArea, i: integer): vector|nil
---@field position fun(self: VoxelArea, i: integer): integer, integer, integer
---@field contains fun(self: VoxelArea, x: integer, y: integer, z: integer): boolean
---@field containsp fun(self: VoxelArea, pos: vector): boolean
---@field containsi fun(self: VoxelArea, i: integer): boolean
---@field iter fun(self: VoxelArea, minx: integer, miny: integer, minz: integer, maxx: integer, maxy: integer, maxz: integer): function
---@field iterp fun(self: VoxelArea, minp: vector, maxp: vector): function
---@field getExtent fun(self: VoxelArea): vector
---@field getVolume fun(self: VoxelArea): integer

---@param minp vector
---@param maxp vector
---@return VoxelArea
function VoxelArea(minp, maxp) end

--- VoxelManip userdata.
---@class VoxelManip
---@field read_from_map fun(self: VoxelManip, p1?: vector, p2?: vector): vector emerged_min, vector emerged_max
---@field initialize fun(self: VoxelManip, p1: vector, p2: vector, node?: {name:string, param1?:integer, param2?:integer}): vector, vector
---@field write_to_map fun(self: VoxelManip, light?: boolean) (light defaults true)
---@field get_data fun(self: VoxelManip, buffer?: table): table
---@field set_data fun(self: VoxelManip, data: table)
---@field get_light_data fun(self: VoxelManip, buffer?: table): table
---@field set_light_data fun(self: VoxelManip, light_data: table)
---@field get_param2_data fun(self: VoxelManip, buffer?: table): table
---@field set_param2_data fun(self: VoxelManip, param2_data: table)
---@field calc_lighting fun(self: VoxelManip, p1?: vector, p2?: vector, propagate_shadow?: boolean)
---@field set_lighting fun(self: VoxelManip, light: {day:integer, night:integer}, p1?: vector, p2?: vector)
---@field get_lighting fun(self: VoxelManip, p1?: vector, p2?: vector): {day:integer, night:integer}
---@field update_liquids fun(self: VoxelManip)
---@field was_modified fun(self: VoxelManip): boolean
---@field get_emerged_area fun(self: VoxelManip): vector, vector
---@field close fun(self: VoxelManip)

---@param pos1? vector
---@param pos2? vector
---@return VoxelManip
function VoxelManip(pos1, pos2) end

--- PseudoRandom (K&R LCG) userdata.
---@class PseudoRandom
---@field next fun(self: PseudoRandom, min?: integer, max?: integer): integer
---@field get_state fun(self: PseudoRandom): integer

---@param seed integer
---@return PseudoRandom
function PseudoRandom(seed) end

--- PcgRandom (PCG32) userdata.
---@class PcgRandom
---@field next fun(self: PcgRandom, min?: integer, max?: integer): integer
---@field next fun(self: PcgRandom, min: integer, max: integer): integer
---@field rand_normal_dist fun(self: PcgRandom, min: integer, max: integer, num_trials?: integer): integer
---@field get_state fun(self: PcgRandom): string
---@field set_state fun(self: PcgRandom, state: string)

---@param seed integer 64‑bit unsigned
---@param seq? integer 64‑bit unsigned sequence
---@return PcgRandom
function PcgRandom(seed, seq) end

--- SecureRandom (OS) userdata.
---@class SecureRandom
---@field next_bytes fun(self: SecureRandom, count?: integer): string

---@return SecureRandom
function SecureRandom() end

--- Raycast userdata.
---@class Raycast
---@field next fun(self: Raycast): pointed_thing|nil

---@param pos1 vector
---@param pos2 vector
---@param objects? boolean (default true)
---@param liquids? boolean (default false)
---@param pointabilities? table
---@return Raycast
function Raycast(pos1, pos2, objects, liquids, pointabilities) end

--- NodeTimerRef userdata.
---@class NodeTimerRef
---@field set fun(self: NodeTimerRef, timeout: number, elapsed: number)
---@field start fun(self: NodeTimerRef, timeout: number)
---@field stop fun(self: NodeTimerRef)
---@field get_timeout fun(self: NodeTimerRef): number
---@field get_elapsed fun(self: NodeTimerRef): number
---@field is_started fun(self: NodeTimerRef): boolean

--- AreaStore userdata.
---@class AreaStore
---@field get_area fun(self: AreaStore, id: integer, include_corners?: boolean, include_data?: boolean): table|nil
---@field get_areas_for_pos fun(self: AreaStore, pos: vector, include_corners?: boolean, include_data?: boolean): table<integer, table>
---@field get_areas_in_area fun(self: AreaStore, corner1: vector, corner2: vector, accept_overlap?: boolean, include_corners?: boolean, include_data?: boolean): table<integer, table>
---@field insert_area fun(self: AreaStore, corner1: vector, corner2: vector, data?: string, id?: integer): integer|nil
---@field reserve fun(self: AreaStore, count: integer)
---@field remove_area fun(self: AreaStore, id: integer): boolean
---@field set_cache_params fun(self: AreaStore, params: {enabled?:boolean, block_radius?:integer, limit?:integer})
---@field to_string fun(self: AreaStore): string
---@field to_file fun(self: AreaStore, filename: string)
---@field from_string fun(self: AreaStore, str: string): boolean, string? err
---@field from_file fun(self: AreaStore, filename: string): boolean, string? err

---@param type_name? "LibSpatial" (default)
---@return AreaStore
function AreaStore(type_name) end

--- ModChannel userdata.
---@class ModChannel
---@field leave fun(self: ModChannel)
---@field is_writeable fun(self: ModChannel): boolean
---@field send_all fun(self: ModChannel, message: string)

--- AsyncJob userdata.
---@class AsyncJob
---@field cancel fun(self: AsyncJob): boolean

--- ValueNoise userdata.
---@class ValueNoise
---@field get_2d fun(self: ValueNoise, pos: {x:number, y:number}): number
---@field get_3d fun(self: ValueNoise, pos: vector): number

---@param noiseparams table
---@return ValueNoise
function ValueNoise(noiseparams) end
---@deprecated
---@param seed integer
---@param octaves integer
---@param persistence number
---@param spread number|vector
---@return ValueNoise
function ValueNoise(seed, octaves, persistence, spread) end

--- ValueNoiseMap userdata.
---@class ValueNoiseMap
---@field get_2d_map fun(self: ValueNoiseMap, pos: {x:number, y:number}): number[][]
---@field get_3d_map fun(self: ValueNoiseMap, pos: vector): number[][][]
---@field get_2d_map_flat fun(self: ValueNoiseMap, pos: {x:number, y:number}, buffer?: table): table
---@field get_3d_map_flat fun(self: ValueNoiseMap, pos: vector, buffer?: table): table
---@field calc_2d_map fun(self: ValueNoiseMap, pos: {x:number, y:number})
---@field calc_3d_map fun(self: ValueNoiseMap, pos: vector)
---@field get_map_slice fun(self: ValueNoiseMap, slice_offset: {x?:integer, y?:integer, z?:integer}, slice_size: {x?:integer, y?:integer, z?:integer}, buffer?: table): table

---@param noiseparams table
---@param size {x:integer, y:integer, z?:integer}
---@return ValueNoiseMap|nil
function ValueNoiseMap(noiseparams, size) end
---@deprecated
---@param noiseparams table
---@param size {x:integer, y:integer, z?:integer}
---@return ValueNoiseMap|nil
function ValueNoiseMap(noiseparams, size) end

--- Base ObjectRef (common methods for all objects).
---@class ObjectRef
---@field is_valid fun(self: ObjectRef): boolean
---@field remove fun(self: ObjectRef)
---@field get_pos fun(self: ObjectRef): vector|nil
---@field set_pos fun(self: ObjectRef, pos: vector)
---@field add_pos fun(self: ObjectRef, pos: vector)
---@field move_to fun(self: ObjectRef, pos: vector, continuous?: boolean)
---@field get_velocity fun(self: ObjectRef): vector
---@field add_velocity fun(self: ObjectRef, vel: vector)
---@field punch fun(self: ObjectRef, puncher: ObjectRef|nil, time_from_last_punch?: number, tool_capabilities?: table, dir?: vector)
---@field right_click fun(self: ObjectRef, clicker: ObjectRef)
---@field set_hp fun(self: ObjectRef, hp: integer, reason?: table)
---@field get_hp fun(self: ObjectRef): integer
---@field get_inventory fun(self: ObjectRef): InvRef|nil
---@field get_wield_list fun(self: ObjectRef): string
---@field get_wield_index fun(self: ObjectRef): integer
---@field get_wielded_item fun(self: ObjectRef): ItemStack
---@field set_wielded_item fun(self: ObjectRef, item: ItemStack|string): boolean
---@field set_armor_groups fun(self: ObjectRef, groups: table<string, integer>)
---@field get_armor_groups fun(self: ObjectRef): table<string, integer>
---@field set_animation fun(self: ObjectRef, frame_range: {x:number, y:number}, frame_speed?: number, frame_blend?: number, frame_loop?: boolean)
---@field set_animation_frame_speed fun(self: ObjectRef, frame_speed: number)
---@field get_animation fun(self: ObjectRef): {frame_range:{x:number,y:number}, frame_speed:number, frame_blend:number, frame_loop:boolean}
---@field set_bone_position fun(self: ObjectRef, bone: string, pos: vector, rot: vector) (deprecated)
---@field get_bone_position fun(self: ObjectRef, bone: string): vector, vector (deprecated)
---@field set_bone_override fun(self: ObjectRef, bone: string, override: table|nil)
---@field get_bone_override fun(self: ObjectRef, bone: string): table
---@field get_bone_overrides fun(self: ObjectRef): table<string, table>
---@field set_attach fun(self: ObjectRef, parent: ObjectRef, bone?: string, pos?: vector, rot?: vector, forced_visible?: boolean)
---@field set_detach fun(self: ObjectRef)
---@field get_attach fun(self: ObjectRef): (ObjectRef|nil, string|nil, vector|nil, vector|nil, boolean|nil)
---@field get_children fun(self: ObjectRef): ObjectRef[]
---@field set_properties fun(self: ObjectRef, props: table)
---@field get_properties fun(self: ObjectRef): table
---@field set_observers fun(self: ObjectRef, observers: table<string, true>|nil)
---@field get_observers fun(self: ObjectRef): table<string, true>|nil
---@field get_effective_observers fun(self: ObjectRef): table<string, true>
---@field get_nametag_attributes fun(self: ObjectRef): {text:string, color:{a:integer,r:integer,g:integer,b:integer}, bgcolor:{a:integer,r:integer,g:integer,b:integer}}
---@field set_nametag_attributes fun(self: ObjectRef, attr: {text?:string, color?:table|string, bgcolor?:table|string|false})
---@field get_guid fun(self: ObjectRef): string
---@field is_player fun(self: ObjectRef): boolean

--- Player object (subclass of ObjectRef).
---@class PlayerRef : ObjectRef
---@field get_player_name fun(self: PlayerRef): string
---@field get_player_velocity fun(self: PlayerRef): vector (deprecated)
---@field add_player_velocity fun(self: PlayerRef, vel: vector) (deprecated)
---@field get_look_dir fun(self: PlayerRef): vector
---@field get_look_horizontal fun(self: PlayerRef): number
---@field get_look_vertical fun(self: PlayerRef): number
---@field set_look_horizontal fun(self: PlayerRef, rad: number)
---@field set_look_vertical fun(self: PlayerRef, rad: number)
---@field get_look_pitch fun(self: PlayerRef): number (deprecated)
---@field get_look_yaw fun(self: PlayerRef): number (deprecated)
---@field set_look_pitch fun(self: PlayerRef, rad: number) (deprecated)
---@field set_look_yaw fun(self: PlayerRef, rad: number) (deprecated)
---@field get_breath fun(self: PlayerRef): integer
---@field set_breath fun(self: PlayerRef, breath: integer)
---@field set_fov fun(self: PlayerRef, fov: number, is_multiplier?: boolean, transition_time?: number)
---@field get_fov fun(self: PlayerRef): number, boolean, number
---@field set_attribute fun(self: PlayerRef, attr: string, value: string|nil) (deprecated)
---@field get_attribute fun(self: PlayerRef, attr: string): string|nil (deprecated)
---@field get_meta fun(self: PlayerRef): PlayerMetaRef
---@field set_inventory_formspec fun(self: PlayerRef, formspec: string)
---@field get_inventory_formspec fun(self: PlayerRef): string
---@field set_formspec_prepend fun(self: PlayerRef, formspec: string)
---@field get_formspec_prepend fun(self: PlayerRef): string
---@field get_player_control fun(self: PlayerRef): {up:boolean, down:boolean, left:boolean, right:boolean, jump:boolean, sneak:boolean, aux1:boolean, zoom:boolean, dig:boolean, place:boolean, movement_x:number, movement_y:number}
---@field get_player_control_bits fun(self: PlayerRef): integer
---@field set_physics_override fun(self: PlayerRef, override: table)
---@field get_physics_override fun(self: PlayerRef): table
---@field hud_add fun(self: PlayerRef, def: table): integer
---@field hud_remove fun(self: PlayerRef, id: integer)
---@field hud_change fun(self: PlayerRef, id: integer, stat: string, value: any)
---@field hud_get fun(self: PlayerRef, id: integer): table|nil
---@field hud_get_all fun(self: PlayerRef): table<integer, table>
---@field hud_set_flags fun(self: PlayerRef, flags: table<string, boolean>)
---@field hud_get_flags fun(self: PlayerRef): table<string, boolean>
---@field hud_set_hotbar_itemcount fun(self: PlayerRef, count: integer)
---@field hud_get_hotbar_itemcount fun(self: PlayerRef): integer
---@field hud_set_hotbar_image fun(self: PlayerRef, texture: string)
---@field hud_get_hotbar_image fun(self: PlayerRef): string
---@field hud_set_hotbar_selected_image fun(self: PlayerRef, texture: string)
---@field hud_get_hotbar_selected_image fun(self: PlayerRef): string
---@field set_minimap_modes fun(self: PlayerRef, modes: table[], selected: integer)
---@field set_sky fun(self: PlayerRef, params: table)
---@field get_sky fun(self: PlayerRef, as_table: true): table
---@field get_sky fun(self: PlayerRef): string, string, string[], boolean (deprecated)
---@field get_sky_color fun(self: PlayerRef): table (deprecated)
---@field set_sun fun(self: PlayerRef, params: table)
---@field get_sun fun(self: PlayerRef): table
---@field set_moon fun(self: PlayerRef, params: table)
---@field get_moon fun(self: PlayerRef): table
---@field set_stars fun(self: PlayerRef, params: table)
---@field get_stars fun(self: PlayerRef): table
---@field set_clouds fun(self: PlayerRef, params: table)
---@field get_clouds fun(self: PlayerRef): table
---@field override_day_night_ratio fun(self: PlayerRef, ratio: number|nil)
---@field get_day_night_ratio fun(self: PlayerRef): number|nil
---@field set_local_animation fun(self: PlayerRef, idle: {x:number,y:number}, walk: {x:number,y:number}, dig: {x:number,y:number}, walk_while_dig: {x:number,y:number}, frame_speed?: number)
---@field get_local_animation fun(self: PlayerRef): {x:number,y:number}, {x:number,y:number}, {x:number,y:number}, {x:number,y:number}, number
---@field set_eye_offset fun(self: PlayerRef, firstperson?: vector, thirdperson_back?: vector, thirdperson_front?: vector)
---@field get_eye_offset fun(self: PlayerRef): vector, vector, vector
---@field set_camera fun(self: PlayerRef, params: {mode:"any"|"first"|"third"|"third_front"})
---@field get_camera fun(self: PlayerRef): {mode:string}
---@field send_mapblock fun(self: PlayerRef, blockpos: vector): boolean
---@field set_lighting fun(self: PlayerRef, lighting: table)
---@field get_lighting fun(self: PlayerRef): table
---@field respawn fun(self: PlayerRef)
---@field get_flags fun(self: PlayerRef): {breathing:boolean, drowning:boolean, node_damage:boolean}
---@field set_flags fun(self: PlayerRef, flags: table)

--- Lua entity object (subclass of ObjectRef).
---@class LuaEntityRef : ObjectRef
---@field set_velocity fun(self: LuaEntityRef, vel: vector)
---@field set_acceleration fun(self: LuaEntityRef, acc: vector)
---@field get_acceleration fun(self: LuaEntityRef): vector
---@field set_rotation fun(self: LuaEntityRef, rot: vector)
---@field get_rotation fun(self: LuaEntityRef): vector
---@field set_yaw fun(self: LuaEntityRef, yaw: number)
---@field get_yaw fun(self: LuaEntityRef): number
---@field set_texture_mod fun(self: LuaEntityRef, mod: string)
---@field get_texture_mod fun(self: LuaEntityRef): string
---@field set_sprite fun(self: LuaEntityRef, start_frame: {x:integer, y:integer}, num_frames: integer, framelength: number, select_x_by_camera?: boolean)
---@field get_luaentity fun(self: LuaEntityRef): table|nil
---@field get_entity_name fun(self: LuaEntityRef): string (deprecated)

--- Item entity object (subclass of ObjectRef, behaves like LuaEntityRef).
---@class ItemEntityRef : LuaEntityRef
-- (no additional unique methods)

--- Base class for all metadata references.
---@class MetaData
---@field contains fun(self: MetaData, key: string): boolean|nil
---@field get fun(self: MetaData, key: string): string|nil
---@field get_string fun(self: MetaData, key: string): string
---@field get_int fun(self: MetaData, key: string): integer
---@field get_float fun(self: MetaData, key: string): number
---@field set_string fun(self: MetaData, key: string, value: string)
---@field set_int fun(self: MetaData, key: string, value: integer)
---@field set_float fun(self: MetaData, key: string, value: number)
---@field get_keys fun(self: MetaData): string[]
---@field to_table fun(self: MetaData): table|nil
---@field from_table fun(self: MetaData, tbl: table): boolean
---@field equals fun(self: MetaData, other: MetaData): boolean

--- Node metadata.
---@class NodeMetaRef: MetaData
---@field get_inventory fun(self: NodeMetaRef): InvRef
---@field mark_as_private fun(self: NodeMetaRef, name: string|string[])

--- ItemStack metadata.
---@class ItemStackMetaRef: MetaData
---@field set_tool_capabilities fun(self: ItemStackMetaRef, caps: table|nil)
---@field set_wear_bar_params fun(self: ItemStackMetaRef, params: table|nil)

--- Player metadata.
---@class PlayerMetaRef: MetaData

--- Mod storage (persistent per mod).
---@class ModStorage: MetaData
---@field reload fun(self: ModStorage)

--- Inventory reference.
---@class InvRef
---@field is_empty fun(self: InvRef, listname: string): boolean
---@field get_size fun(self: InvRef, listname: string): integer
---@field set_size fun(self: InvRef, listname: string, size: integer): boolean
---@field get_width fun(self: InvRef, listname: string): integer
---@field set_width fun(self: InvRef, listname: string, width: integer): boolean
---@field get_stack fun(self: InvRef, listname: string, i: integer): ItemStack
---@field set_stack fun(self: InvRef, listname: string, i: integer, stack: ItemStack)
---@field get_list fun(self: InvRef, listname: string): ItemStack[]|nil
---@field set_list fun(self: InvRef, listname: string, list: ItemStack[])
---@field get_lists fun(self: InvRef): table<string, ItemStack[]>
---@field set_lists fun(self: InvRef, lists: table<string, ItemStack[]>)
---@field add_item fun(self: InvRef, listname: string, stack: ItemStack): ItemStack
---@field room_for_item fun(self: InvRef, listname: string, stack: ItemStack): boolean
---@field contains_item fun(self: InvRef, listname: string, stack: ItemStack, match_meta?: boolean): boolean
---@field remove_item fun(self: InvRef, listname: string, stack: ItemStack, match_meta?: boolean): ItemStack
---@field get_location fun(self: InvRef): {type: string}

--- Detached inventory callbacks.
---@class DetachedInventoryCallbacks
---@field allow_move? fun(inv:InvRef, from_list:string, from_index:integer, to_list:string, to_index:integer, count:integer, player:ObjectRef): integer
---@field allow_put? fun(inv:InvRef, listname:string, index:integer, stack:ItemStack, player:ObjectRef): integer
---@field allow_take? fun(inv:InvRef, listname:string, index:integer, stack:ItemStack, player:ObjectRef): integer
---@field on_move? fun(inv:InvRef, from_list:string, from_index:integer, to_list:string, to_index:integer, count:integer, player:ObjectRef)
---@field on_put? fun(inv:InvRef, listname:string, index:integer, stack:ItemStack, player:ObjectRef)
---@field on_take? fun(inv:InvRef, listname:string, index:integer, stack:ItemStack, player:ObjectRef)

--- Dump any value to a human‑readable string (for debugging).
---@param value any
---@param dumped? table (for internal circular reference tracking)
---@return string
function dump(value, dumped) end