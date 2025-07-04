# Inventory Admin

## Description
 Inventory Admin allows players with the `invmanage` privilege to view and manage the inventory of other players. This tool is particularly useful for server admins or for use in special gameplay scenarios.

## Features
- View and manage other players' inventories.
- Works with `minetest_game` and MineClone2.
- Provides a command for easy access to any player's inventory.
- Detached inventory support for seamless inventory management.
- Real-time inventory sync.

## Usage
To use the Inventory Admin mod, you must have the `invmanage` privilege.

- Grant the privilege to a player using the command: `/grant <playername> invmanage`
- To view and manage a player's inventory, use the command: `/invmanage <playername>`

## Commands
- `/invmanage <playername>`: Opens the formspec for the target player's inventory.

## Privileges
- `invmanage`: Allows viewing and managing of other players' inventories.

## API
- `inventory_admin.setup_detached_inventory(player_name)`: Set up a detached inventory for the player.
- `inventory_admin.sync_player_to_detached_inventory(player_name)`: Sync a player's inventory to the detached inventory.
- `inventory_admin.sync_inventory_to_player(player_name)`: Sync the detached inventory back to the player's inventory.

## Dependencies
- Default Minetest game or MineClone2.

## License
Licensed under the `GPLv3 or later` license
[LICENSE FILE HERE](./LICENSE)
Can be found in root of project.

## Author
Impulse (James Clarke)
