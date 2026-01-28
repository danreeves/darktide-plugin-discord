# Darktide Discord Rich Presence

Uses the Stingray Plugin API to integrate the Discord Game SDK into Darktide.

Credit to [thewhitegoatcb](https://github.com/thewhitegoatcb/rawray) for reverse engineering the Vermintide 2 Plugin API.

<p align="center">
	<img src="./assets/Screenshot1.png"/>
</p>

## Installation

Place `darktide_discord_pluginw64.dll` in the `[game install]/binaries/plugins/` directory.

## Building

This project uses the Discord Game SDK C bindings. To build:

```bash
make
```

### Requirements

- MinGW-w64 cross-compiler (x86_64-w64-mingw32-g++)
- Discord Game SDK (included in `discord_game_sdk/`)

### Discord Game SDK

The project uses the C bindings from the Discord Game SDK, located in `discord_game_sdk/c/`. The header file includes the recommended `#pragma pack` directives for compatibility:

```c
#pragma pack(push, 8)
#include "discord_game_sdk.h"
#pragma pack(pop)
```

### Cross-compilation

On Linux, you can install the MinGW cross-compiler:

```bash
sudo apt-get install mingw-w64
```

Then compile with:

```bash
x86_64-w64-mingw32-g++ -Wall -Wextra -std=c++11 -shared -Os \
  -I./src/lua -I./discord_game_sdk/c \
  -L./discord_game_sdk/lib/x86_64 -ldiscord_game_sdk \
  -o darktide_discord_pluginw64.dll src/darktide_discord.cpp
```

## API

The plugin exposes a Lua API for mods to use.

```lua
-- The version of the Darktide Discord plugin binary
DarktideDiscord.VERSION: number

-- Set the player's current party status
DarktideDiscord.set_state(state: string)

-- Set what the player is currently doing
DarktideDiscord.set_details(details: string)

-- Set the players current career archetype and details
DarktideDiscord.set_class(class: string, details: string)

-- Set the number of players in the current party
DarktideDiscord.set_party_size(size: number)

-- Reset the gameplay timer to 0
DarktideDiscord.set_start_time()

-- Call this in the game looop
DarktideDiscord.update();
```
