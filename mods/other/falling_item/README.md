falling.lua replacement

edited by TenPlus1

Features:
- Added new group {falling_node_hurt} to hurt player or mobs below falling items
- Falling nodes will only replace airlike, buildable to, water and attached nodes
- Any attached nodes will drop as item when replaced
- Added horizontal slowing for when TNT blasts a falling node
- Falling nodes removed when outside map only
- Added 'falling_step(self, pos, dtime)' custom on_step for falling items
   'self' contains falling object data
   'self.node' is the node currently falling
   'self.meta' is the metadata contained within the falling node
   'pos' holds position of falling item
   'dtime' used for timers

   return false to skip further checks by falling_item

Additional:
 - Falling nodes with a light source fall with glow active
 - Torchlike or signlike nodes fall with different drawtypes
 - Thanks to Wuzzy for both of the above features :)

License: MIT


falling_step() example

minetest.override_item("default:gravel", {
	falling_step = function(self, pos, dtime)
		print (self.node.name .. " falling!", dtime)
	end
})
