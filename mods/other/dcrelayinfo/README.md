# Minetest Discord Relay Info

This mod relays real-time information from **Minetest CTF** to a Discord channel via a **webhook**.  
Its purpose is to reduce the lag caused by the classic relay mod and improve the readability of game information on Discord.

---

## Features

- Works through a **Discord webhook**, reducing server performance impact.  
- Retrieves data directly using functions from **CTF**.  
- The message on Discord is **updated every second** (except on startup, where it begins after 5 seconds).  
- The **Discord message ID** is stored in `world/match_message_id.txt`:
  - If the file is deleted → a new one is automatically created.  
  - If the Discord message is deleted → a new message with a new ID is generated.  
- Prevents spam in the **#ctf︱ingame-chat** channel while providing more detailed information on Discord.  
- The message interface is optimized so that the **top 50 and match info** are viewable on all devices.  

---

## Installation

1. Download and install the mod into your `mods/` directory.  
2. Add the following configuration to your `minetest.conf` file:

```conf
dcrelayinfo.url = <webhook url>
secure.http_mods = dcrelayinfo
secure.enable_security = true
