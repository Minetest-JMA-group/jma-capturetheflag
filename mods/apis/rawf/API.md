## Custom item definition values

```lua
{
	-- Name of the loaded version of the ranged weapon
	-- Used by: load_weapon()
	-- Set by: also_register_loaded_tool()
	loaded_name = <string>,

	-- Name of the unloaded version of the ranged weapon
	-- Used by: unload_weapon()
	-- Set by: also_register_loaded_tool()
	unloaded_name = <string>,

	-- Amount of bullets the ranged weapon can shoot.
	-- Used by: unload_weapon()
	rounds = <number>,

	-- Ammo that can be used by the ranged weapon
	-- Used by: load_weapon()
	ammo = <itemstack | string | list>
}
```
