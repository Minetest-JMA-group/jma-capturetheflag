# JMA Capture The Flag

## Installation

### Git

Capture the flag uses several submodules. Make sure to grab them all by cloning like this:

```sh
git clone --recursive https://codeberg.org/Minetest-JMA-group/jma-capturetheflag.git
```
(Using ssh to clone is recommended for developers/contributors)

## Recommended Setup

* Hosting your server using the `dummy` backend.

### For public servers:
* Storing rankings using the `redis` backend, all steps are required:
  * Install redis, luarocks, and luaredis (Ubuntu)
    * `sudo apt install luarocks redis`
    * `sudo luarocks install luaredis`
  * Add `ctf_rankings` to your `secure.trusted_mods`
	* Make sure you don't add any malicious mods to your server. **It is possible they can breach the sandbox through `ctf_rankings` when it is a trusted mod**
  * Run something like this when starting your server: `(cd minetest/worlds/yourworld && redis-server) | <command to launch your minetest server>`
    * If you run your Minetest server using a system service it is recommended to run redis-server on a seperate service, with the Minetest service depending upon it

## Starting a game (GUI instructions)
* Create a new `singlenode` world
* Turn on `Enable Damage` and `Host Server`, turn off `Creative Mode`, *memorize* your port
* Click `Host Game`, a round should automatically start as soon as you join in
* Players on your LAN can join using your local IP and the port you *memorize*d

## Development

* ### [WIP CTF API DOCS](docs/ctf-api.md)
* If you use Visual Studio Code we recommend these extensions:
  * https://marketplace.visualstudio.com/items?itemName=sumneko.lua
  * https://marketplace.visualstudio.com/items?itemName=dwenegar.vscode-luacheck

## Contributing

Contributions to JMA CTF are very welcome. In issues, you can find something to work on. Note that issues with "Undecided" label means the staff team haven't come to a conclusion if the change is fit for the game. Discussion on them is welcome. But please don't work on them as with rejection, your time and effort will be wasted.

When submitting changes:

 - Do one logical thing in a PR
 - Comments, variable names, function names and such these MUST be in English.
 - Code quality and implementation details are very important. We won't merge your patches just because the feature you added works. But it also must be idiomatic and well written. If you aren't an experienced developer, don't worry about this! Simply ask on the issue what is the best way to make some change. And then create a draft PR. So we can see your changes before they complete to put you in a good way.

Apart from the issues, there are two other important changes you can send patches for(the most important first):

 - Using Lua Language Server type hints. Please add proper type hints for the variables, function parameters, return types and so on.
 - Using Luanti's translation API for the game. The game has a history before Luanti had this.
 - Translating the game into your language. Note that if you want to translate a mod, the mod must already be using the translation API.

## License

Created by [rubenwardy](https://rubenwardy.com/).
Developed by [LandarVargan](https://github.com/LoneWolfHT).
Previous Developers: [savilli](https://github.com/savilli).

Check out [mods/](mods/) to see all the installed mods and their respective licenses.

Licenses where not specified:
Code: LGPLv2.1+
Textures: CC-BY-SA 3.0

### Credits

JMA CTF game is a fork of "main" CTF game which currently is in hands of LoneWolfHT in [this repository](https://github.com/MT-CTF/capturetheflag). We have our own server and our philosophies both in game developement and management are very different than main CTF game. We are far more open to changes. But this also means that sometimes the game could become worse by adding a new feature it doesn't fit, till we fix it!

You can check the git repository for a full history of commits and their authors.

### Textures

* [Header](menu/header.png): CC-BY-3.0 by [SuddenSFD](https://github.com/SuddenSFD)
* [Background Image](menu/background.png): CC BY-SA 4.0 (where applicable) by [GreenBlob](https://github.com/a-blob) (Uses [Minetest Game](https://github.com/minetest/minetest_game) textures, the majority of which are licensed CC-BY-SA 3.0). The player skins used are licensed CC-BY-SA 3.0
* [Icon](menu/icon.png): CC-BY-3.0 by [SuddenSFD](https://github.com/SuddenSFD)
