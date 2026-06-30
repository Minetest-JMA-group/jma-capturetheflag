---@meta

-- table extensions
---@param list table
---@param val any
---@return integer|nil
function table.indexof(list, val) end

---@param t table
---@return table
function table.copy(t) end

---@param t table
---@return table
function table.copy_with_metatables(t) end

---@param dest table
---@param src table
function table.insert_all(dest, src) end

---@param t table
---@param from? integer
---@param to? integer
---@param random_func? fun(min:integer, max:integer):integer
function table.shuffle(t, from, to, random_func) end

---@param t table
---@return table
function table.key_value_swap(t) end

---@param t table
---@param val any
---@return any|nil
function table.keyof(t, val) end

-- string extensions
---@param separator string
---@param include_empty? boolean
---@param max_splits? integer
---@param sep_is_pattern? boolean
---@return string[]
function string:split(separator, include_empty, max_splits, sep_is_pattern) end

---@return string
function string:trim() end

-- math extensions
---@param x number
---@param y number
---@return number
function math.hypot(x, y) end

---@param x number
---@param tolerance? number
---@return -1|0|1
function math.sign(x, tolerance) end

---@param x integer
---@return integer
function math.factorial(x) end

---@param x number
---@return integer
function math.round(x) end

---@param x number
---@return boolean
function math.isfinite(x) end

-- vector
---@class simplevector
---@field x number
---@field y number
---@field z number
---@field to_string? fun(self: simplevector): string

---@class vector : simplevector
---@field to_string fun(self: vector): string
---@field copy fun(self: vector): vector
---@field length fun(self: vector): number

-- metadata
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

---@class PlayerMetaRef : MetaData

---@class InvRef
---@field is_empty fun(self: InvRef, listname: string): boolean
---@field get_size fun(self: InvRef, listname: string): integer
---@field set_size fun(self: InvRef, listname: string, size: integer): boolean
---@field get_stack fun(self: InvRef, listname: string, i: integer): ItemStack
---@field set_stack fun(self: InvRef, listname: string, i: integer, stack: ItemStack)
---@field get_list fun(self: InvRef, listname: string): ItemStack[]|nil
---@field set_list fun(self: InvRef, listname: string, list: ItemStack[])
---@field add_item fun(self: InvRef, listname: string, stack: any): ItemStack
---@field room_for_item fun(self: InvRef, listname: string, stack: any): boolean
---@field contains_item fun(self: InvRef, listname: string, stack: any, match_meta?: boolean): boolean
---@field remove_item fun(self: InvRef, listname: string, stack: any, match_meta?: boolean): ItemStack
---@field get_location fun(self: InvRef): {type: string}

---@class HUDDefinition
---@field type "compass"|"hotbar"|"image"|"image_waypoint"|"inventory"|"minimap"|"statbar"|"text"|"waypoint"
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
---@field world_pos? simplevector
---@field size? {x:number, y:number}
---@field z_index? integer
---@field style? integer
---@field image_scale_map? number

---@class ItemStack
---@field get_name fun(self: ItemStack): string
---@field get_count fun(self: ItemStack): integer
---@field get_wear fun(self: ItemStack): integer
---@field set_wear fun(self: ItemStack, wear: integer)
---@field get_meta fun(self: ItemStack): ItemStackMetaRef
---@field get_definition fun(self: ItemStack): table
---@field to_string fun(self: ItemStack): string
---@class ItemRepresentation
---@class TileDefinitionTable
---@class PlayerHPChangeReason

-- ObjectRef (base class for PlayerRef and others)
---@class ObjectRef
---@field remove fun(self: ObjectRef)
---@field get_pos fun(self: ObjectRef): vector
---@field set_pos fun(self: ObjectRef, pos: vector)
---@field get_velocity fun(self: ObjectRef): vector
---@field add_velocity fun(self: ObjectRef, vel: vector)
---@field punch fun(self: ObjectRef, puncher: ObjectRef?, time_from_last_punch?: number, tool_capabilities?: any, dir?: any)
---@field right_click fun(self: ObjectRef, clicker: ObjectRef?)
---@field set_hp fun(self: ObjectRef, hp: integer, reason?: any)
---@field get_hp fun(self: ObjectRef): integer
---@field get_inventory fun(self: ObjectRef): InvRef
---@field get_wielded_item fun(self: ObjectRef): ItemStack
---@field set_wielded_item fun(self: ObjectRef, item: any): boolean
---@field set_properties fun(self: ObjectRef, props: table)
---@field get_properties fun(self: ObjectRef): table
---@field set_observers fun(self: ObjectRef, observers: table)
---@field get_luaentity fun(self: ObjectRef): table
---@field is_player fun(self: ObjectRef): boolean
---@field get_name fun(self: ObjectRef): string
---@field get_meta fun(self: ObjectRef): MetaData
---@field get_player_name fun(self: ObjectRef): string
---@field set_physics_override fun(self: ObjectRef, override: table)
---@field get_physics_override fun(self: ObjectRef): table
---@field set_look_horizontal fun(self: ObjectRef, rad: number)
---@field set_look_vertical fun(self: ObjectRef, rad: number)
---@field get_look_horizontal fun(self: ObjectRef): number
---@field get_look_vertical fun(self: ObjectRef): number
---@field get_look_dir fun(self: ObjectRef): simplevector
---@field get_player_control fun(self: ObjectRef): table
---@field get_player_velocity fun(self: ObjectRef): simplevector
---@field add_player_velocity fun(self: ObjectRef, vel: simplevector)
---@field hud_add fun(self: ObjectRef, def: HUDDefinition): integer
---@field hud_remove fun(self: ObjectRef, id: integer)
---@field hud_change fun(self: ObjectRef, id: integer, stat: string, value: any)
---@field hud_set_hotbar_itemcount fun(self: ObjectRef, count: integer)
---@field hud_set_hotbar_image fun(self: ObjectRef, texture: string)
---@field hud_set_hotbar_selected_image fun(self: ObjectRef, texture: string)
---@field respawn fun(self: ObjectRef)
---@field set_eye_offset fun(self: ObjectRef, firstperson?: simplevector, thirdperson_back?: simplevector, thirdperson_front?: simplevector)
---@field get_eye_offset fun(self: ObjectRef): simplevector, simplevector, simplevector
---@field set_attribute fun(self: ObjectRef, attr: string, value: any)
---@field get_attribute fun(self: ObjectRef, attr: string): any
---@field set_inventory_formspec fun(self: ObjectRef, formspec: string)
---@field get_inventory_formspec fun(self: ObjectRef): string
---@field set_formspec_prepend fun(self: ObjectRef, formspec: string)
---@field get_formspec_prepend fun(self: ObjectRef): string
---@field set_bone_position fun(self: ObjectRef, bone: string, pos: simplevector, rot: simplevector)
---@field get_bone_position fun(self: ObjectRef, bone: string): simplevector, simplevector
---@field set_animation fun(self: ObjectRef, frame_range: any, frame_speed?: number, frame_blend?: number, frame_loop?: boolean)
---@field get_animation fun(self: ObjectRef): any
---@field set_attach fun(self: ObjectRef, parent: ObjectRef, bone?: string, pos?: simplevector, rot?: simplevector, forced_visible?: boolean)
---@field set_detach fun(self: ObjectRef)
---@field set_nametag_attributes fun(self: ObjectRef, attr: table)

-- PlayerRef (subclass of ObjectRef, inherits all fields)
---@class PlayerRef : ObjectRef

---@class ItemStackMetaRef : MetaData
---@alias player PlayerRef
