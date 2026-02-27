---@meta

--- Vector type (a table with x, y, z fields).
---@class vector
---@field x number
---@field y number
---@field z number

--- Vector manipulation library.
---@class VectorLib
vector = {}

---@return vector
function vector.zero() end

---@param x number|vector
---@param y? number
---@param z? number
---@return vector
function vector.new(x, y, z) end

---@param v vector
---@return vector
function vector.copy(v) end

---@param a vector
---@param b vector
---@return vector
function vector.add(a, b) end

---@param a vector
---@param b vector
---@return vector
function vector.subtract(a, b) end

---@param v vector
---@param s number
---@return vector
function vector.multiply(v, s) end

---@param v vector
---@param s number
---@return vector
function vector.divide(v, s) end

---@param v vector
---@return number
function vector.length(v) end

---@param v vector
---@return vector
function vector.normalize(v) end

---@param v vector
---@return vector
function vector.round(v) end

---@param a vector
---@param b vector
---@return number
function vector.distance(a, b) end

---@param a vector
---@param b vector
---@return number
function vector.dot(a, b) end

---@param a vector
---@param b vector
---@return vector
function vector.cross(a, b) end

---@param a vector
---@param b vector
---@return boolean
function vector.equals(a, b) end

---@param v vector
---@param func fun(n: number): number
---@return vector
function vector.apply(v, func) end

--- Returns the direction vector from p1 to p2 (normalized).
---@param p1 vector
---@param p2 vector
---@return vector
function vector.direction(p1, p2) end

---@param yaw number (radians)
---@return vector
function vector.new_from_yaw(yaw) end

---@param v vector
---@return number yaw (radians)
function vector.to_yaw(v) end

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
---@field get_description fun(self: ItemStack): string
---@field get_short_description fun(self: ItemStack): string|nil
---@field to_string fun(self: ItemStack): string
---@field to_table fun(self: ItemStack): table|nil
---@field get_stack_max fun(self: ItemStack): integer
---@field get_free_space fun(self: ItemStack): integer
---@field is_known fun(self: ItemStack): boolean
---@field get_definition fun(self: ItemStack): table
---@field get_tool_capabilities fun(self: ItemStack): table|nil
---@field add_wear fun(self: ItemStack, amount: integer)
---@field add_wear_by_uses fun(self: ItemStack, max_uses: integer)
---@field add_item fun(self: ItemStack, stack: ItemStack|string): ItemStack
---@field item_fits fun(self: ItemStack, stack: ItemStack|string): boolean
---@field take_item fun(self: ItemStack, n?: integer): ItemStack
---@field peek_item fun(self: ItemStack, n?: integer): ItemStack

--- Constructor for ItemStack.
---@param itemstring? string|table|ItemStack
---@return ItemStack
function ItemStack(itemstring) end

--- VoxelArea userdata.
---@class VoxelArea
---@field MinEdge vector
---@field MaxEdge vector
---@field index fun(self: VoxelArea, pos: vector): integer
---@field index fun(self: VoxelArea, x: number, y: number, z: number): integer
---@field position fun(self: VoxelArea, i: integer): vector|nil
---@field position fun(self: VoxelArea, i: integer): number, number, number
---@field contains fun(self: VoxelArea, pos: vector): boolean
---@field getExtent fun(self: VoxelArea): vector
---@field getVolume fun(self: VoxelArea): integer

---@param minp vector
---@param maxp vector
---@return VoxelArea
function VoxelArea(minp, maxp) end

--- VoxelManip userdata.
---@class VoxelManip
---@field read_from_map fun(self: VoxelManip, pos1?: vector, pos2?: vector): {content: table, param1: table, param2: table}
---@field write_to_map fun(self: VoxelManip)
---@field get_data fun(self: VoxelManip): table
---@field set_data fun(self: VoxelManip, data: table)
---@field get_light_data fun(self: VoxelManip): table
---@field set_light_data fun(self: VoxelManip, data: table)
---@field get_param1_data fun(self: VoxelManip): table
---@field set_param1_data fun(self: VoxelManip, data: table)
---@field get_param2_data fun(self: VoxelManip): table
---@field set_param2_data fun(self: VoxelManip, data: table)
---@field calc_lighting fun(self: VoxelManip)
---@field update_liquids fun(self: VoxelManip)
---@field set_lighting fun(self: VoxelManip, light: table, minp?: vector, maxp?: vector)
---@field get_lighting fun(self: VoxelManip, minp?: vector, maxp?: vector): table

---@param pos1? vector
---@param pos2? vector
---@return VoxelManip
function VoxelManip(pos1, pos2) end

--- PseudoRandom userdata (32‑bit seed, predictable sequence).
---@class PseudoRandom
---@field next fun(self: PseudoRandom, min?: integer, max?: integer): integer

---@param seed integer
---@return PseudoRandom
function PseudoRandom(seed) end

--- ObjectRef userdata (players, entities, items).
---@class ObjectRef
---@field is_valid fun(self: ObjectRef): boolean
---@field remove fun(self: ObjectRef)
---@field get_pos fun(self: ObjectRef): vector|nil
---@field move_to fun(self: ObjectRef, pos: vector, continuous?: boolean): boolean
---@field set_pos fun(self: ObjectRef, pos: vector): boolean
---@field punch fun(self: ObjectRef, puncher: ObjectRef, time_from_last_punch?: number, tool_capabilities?: table, dir?: vector)
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
---@field set_animation fun(self: ObjectRef, animation: {x: integer, y: integer}, frame_speed?: integer, frame_blend?: integer, frame_loop?: boolean)
---@field set_bone_position fun(self: ObjectRef, bone: string, pos: vector, rot: vector)
---@field get_bone_position fun(self: ObjectRef, bone: string): vector, vector
---@field set_attach fun(self: ObjectRef, parent: ObjectRef, bone?: string, pos?: vector, rot?: vector, force_visible?: boolean)
---@field set_detach fun(self: ObjectRef)
---@field get_attach fun(self: ObjectRef): ObjectRef|nil, string|nil
---@field set_properties fun(self: ObjectRef, prop: table)
---@field get_properties fun(self: ObjectRef): table
---@field get_player_name fun(self: ObjectRef): string
---@field get_look_dir fun(self: ObjectRef): vector
---@field get_look_horizontal fun(self: ObjectRef): number
---@field get_look_vertical fun(self: ObjectRef): number
---@field set_look_horizontal fun(self: ObjectRef, yaw: number)
---@field set_look_vertical fun(self: ObjectRef, pitch: number)
---@field set_physics_override fun(self: ObjectRef, override: {speed?: number, jump?: number, gravity?: number, sneak?: boolean, sneak_glitch?: boolean})
---@field get_physics_override fun(self: ObjectRef): table
---@field hud_add fun(self: ObjectRef, huddef: table): integer
---@field hud_change fun(self: ObjectRef, id: integer, stat: string, value: any)
---@field hud_remove fun(self: ObjectRef, id: integer)
---@field hud_get fun(self: ObjectRef, id: integer): table|nil
---@field hud_get_all fun(self: ObjectRef): table[]
---@field set_inventory_formspec fun(self: ObjectRef, formspec: string)
---@field get_inventory_formspec fun(self: ObjectRef): string
---@field set_formspec_prepend fun(self: ObjectRef, formspec: string)
---@field get_formspec_prepend fun(self: ObjectRef): string
---@field get_player_control fun(self: ObjectRef): {up: boolean, down: boolean, left: boolean, right: boolean, jump: boolean, sneak: boolean, aux1: boolean, zoom: boolean, dig: boolean, place: boolean}
---@field get_meta fun(self: ObjectRef): PlayerMetaRef

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
---@field to_table fun(self: MetaData): table
---@field from_table fun(self: MetaData, tbl: table): boolean
---@field equals fun(self: MetaData, other: MetaData): boolean

--- Node metadata.
---@class NodeMetaRef: MetaData

--- ItemStack metadata.
---@class ItemStackMetaRef: MetaData

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
---@field add_item fun(self: InvRef, listname: string, stack: ItemStack): ItemStack
---@field room_for_item fun(self: InvRef, listname: string, stack: ItemStack): boolean
---@field contains_item fun(self: InvRef, listname: string, stack: ItemStack, match_meta?: boolean): boolean
---@field remove_item fun(self: InvRef, listname: string, stack: ItemStack, match_meta?: boolean): ItemStack
---@field get_location fun(self: InvRef): {type: string}

--- Dump any value to a human-readable string (for debugging).
---@param value any
---@param dumped? table (circular reference tracking)
---@return string
function dump(value, dumped) end