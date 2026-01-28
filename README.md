# Darktide Discord Rich Presence

Uses the Stingray Plugin API to integrate the Discord Game SDK into Darktide.

Credit to [thewhitegoatcb](https://github.com/thewhitegoatcb/rawray) for reverse engineering the Vermintide 2 Plugin API.

<p align="center">
	<img src="./assets/Screenshot1.png"/>
</p>

## Installation

Place `darktide_discord_pluginw64.dll` in the `[game install]/binaries/plugins/` directory.

## Building

This project is written in Zig and uses the Discord Game SDK C bindings.

### Requirements

- [Zig](https://ziglang.org/download/) (version 0.13.0 or later)
- Discord Game SDK (included in `discord_game_sdk/`)

### Build with Zig (Recommended)

```bash
zig build
```

The DLL will be output to `zig-out/lib/darktide_discord_pluginw64.dll`.

### Build Options

```bash
# Build in release mode (optimized)
zig build -Doptimize=ReleaseFast

# Build in debug mode
zig build
```

### Cross-compilation

Zig includes cross-compilation support by default. The build is configured to target Windows x86_64 automatically, so you can build from Linux, macOS, or Windows.

### Discord Game SDK

The project uses the C bindings from the Discord Game SDK, located in `discord_game_sdk/c/`. The Zig code imports the C header directly:

```zig
const c = @cImport({
    @cInclude("discord_game_sdk.h");
});
```

This provides the same functionality as the C++ wrapper but with a simpler, more direct API.

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

## Development

The plugin is implemented in Zig (`src/darktide_discord.zig`) and links directly to the Discord Game SDK C library. The build system (`build.zig`) handles all compilation and linking automatically.
