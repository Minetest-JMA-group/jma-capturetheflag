# minetest-mod-rocket_launcher
Simple rocket launcher that uses tnt.explode() function  
![ContentDB](https://content.minetest.net/packages/Zemtzov7/rocket_launcher/shields/downloads/)
### Features
* Rockets are 3d meshes
* Default radius can be set in settings - `rocket_launcher_radius`, default is `3`,
* Also radius can be set individually for each launcher(radius will displayed in item icon, e.g. `R12`) by the `/rocket-radius <number>` command(keep launcher in the hand to use this command)
* Rocket's ballistic enabled by default and can be disabled in settings(`rocket_launcher_ballistic = false`)
* Explosions in protected areas (damage only, not breaking nodes) can be enabled by setting `rocket_launcher_safe_areas` to `false`

### License of media (textures and model)
* `rocket.obj` - by Zemtzov7. License - CC-BY-SA-4.0
* `rocket.png`, `rocket_launcher.png`, `rocket_mesh.png` - by Zemtzov7, License - CC-BY-SA-4.0
