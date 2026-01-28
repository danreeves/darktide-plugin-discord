# Conversion to Discord Game SDK C Bindings

## Summary

This project has been successfully converted from using the Discord Game SDK C++ API to using the C bindings. The conversion was completed following the recommendations in the Discord Game SDK documentation.

## Key Changes

### 1. Source Code (`src/darktide_discord.cpp`)

**Before (C++ API):**
```cpp
#include "discord/discord.h"
discord::Core *core{};
discord::Activity activity{};

auto result = discord::Core::Create(id, flags, &core);
activity.SetState(value);
core->ActivityManager().UpdateActivity(activity, callback);
core->RunCallbacks();
```

**After (C API):**
```cpp
#pragma pack(push, 8)
#include "discord_game_sdk.h"
#pragma pack(pop)

struct IDiscordCore* core = nullptr;
struct IDiscordActivityManager* activities = nullptr;
struct DiscordActivity activity;

DiscordCreate(DISCORD_VERSION, &params, &core);
strncpy(activity.state, value, 127);
activities->update_activity(activities, &activity, nullptr, callback);
core->run_callbacks(core);
```

### 2. Build System

- **Makefile**: Updated to use `discord_game_sdk/c` and `discord_game_sdk/lib/x86_64`
- **Removed**: C++ Discord SDK wrapper compilation (`src/discord/*.cpp`)
- **Added**: Direct linking to Discord Game SDK DLL

### 3. API Differences

| Operation | C++ API | C API |
|-----------|---------|-------|
| Set State | `activity.SetState(str)` | `strncpy(activity.state, str, 127)` |
| Set Details | `activity.SetDetails(str)` | `strncpy(activity.details, str, 127)` |
| Update Activity | `core->ActivityManager().UpdateActivity(...)` | `activities->update_activity(activities, ...)` |
| Run Callbacks | `core->RunCallbacks()` | `core->run_callbacks(core)` |
| Set Party Size | `activity.GetParty().GetSize().SetCurrentSize(n)` | `activity.party.size.current_size = n` |

### 4. Compilation

**Command:**
```bash
x86_64-w64-mingw32-g++ -Wall -Wextra -std=c++11 -shared -Os \
  -I./src/lua -I./discord_game_sdk/c \
  -L./discord_game_sdk/lib/x86_64 -ldiscord_game_sdk \
  -o darktide_discord_pluginw64.dll src/darktide_discord.cpp
```

**Output:**
- DLL Size: 217KB
- Format: PE32+ executable (DLL) for MS Windows x86-64
- Exports: `get_plugin_api` (verified)

## Benefits of C API

1. **Simpler Linking**: No need to compile C++ wrapper files
2. **Better Compatibility**: C ABI is more stable across compilers
3. **Smaller Binary**: Reduced code size from not including C++ wrapper
4. **Official Support**: Following Discord's recommended C binding pattern

## Testing

The DLL has been successfully compiled and verified:
- ✅ Compiles without errors (only minor unused parameter warnings)
- ✅ Correct PE32+ DLL format
- ✅ Exports `get_plugin_api` function
- ✅ Links against Discord Game SDK DLL

## Files Modified

- `src/darktide_discord.cpp` - Rewritten to use C API
- `Makefile` - Updated paths and removed C++ wrapper compilation
- `README.md` - Updated build instructions
- `build.zig` - Updated for Zig build (alternative build system)
- `discord_game_sdk/c/Windows.h` - Symlink for case-sensitive filesystems
- `discord_game_sdk/c/dxgi.h` - Symlink for case-sensitive filesystems

## Future Considerations

The `build.zig` file provides an alternative build system using Zig, but the Makefile with MinGW remains the primary build method. The Zig implementation in `src/darktide_discord.zig` mirrors the C API usage pattern.
