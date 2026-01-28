# Discord Game SDK: C++ vs C API Comparison

This document shows side-by-side comparison of the key API calls before and after conversion.

## Initialization

### C++ API (Before)
```cpp
discord::Core *core{};
discord::Activity activity{};

__int64 id = 1111429477055090698;
auto result = discord::Core::Create(id, DiscordCreateFlags_NoRequireDiscord, &core);
```

### C API (After)
```cpp
struct IDiscordCore* core = nullptr;
struct IDiscordActivityManager* activities = nullptr;
struct DiscordActivity activity;

struct DiscordCreateParams params;
DiscordCreateParamsSetDefault(&params);
params.client_id = 1111429477055090698;
params.flags = DiscordCreateFlags_NoRequireDiscord;

DiscordCreate(DISCORD_VERSION, &params, &core);
activities = core->get_activity_manager(core);
memset(&activity, 0, sizeof(activity));
```

## Setting Activity State

### C++ API (Before)
```cpp
activity.SetState("In Mission");
```

### C API (After)
```cpp
strncpy(activity.state, "In Mission", 127);
activity.state[127] = '\0';
```

## Setting Activity Details

### C++ API (Before)
```cpp
activity.SetDetails("Fighting Heretics");
```

### C API (After)
```cpp
strncpy(activity.details, "Fighting Heretics", 127);
activity.details[127] = '\0';
```

## Setting Party Size

### C++ API (Before)
```cpp
activity.GetParty().GetSize().SetCurrentSize(3);
activity.GetParty().GetSize().SetMaxSize(4);
```

### C API (After)
```cpp
activity.party.size.current_size = 3;
activity.party.size.max_size = 4;
```

## Setting Asset Images

### C++ API (Before)
```cpp
activity.GetAssets().SetLargeImage("darktide");
activity.GetAssets().SetSmallImage("zealot");
activity.GetAssets().SetSmallText("Zealot - Level 30");
```

### C API (After)
```cpp
strncpy(activity.assets.large_image, "darktide", 127);
activity.assets.large_image[127] = '\0';

strncpy(activity.assets.small_image, "zealot", 127);
activity.assets.small_image[127] = '\0';

strncpy(activity.assets.small_text, "Zealot - Level 30", 127);
activity.assets.small_text[127] = '\0';
```

## Updating Activity

### C++ API (Before)
```cpp
core->ActivityManager().UpdateActivity(
    activity, 
    [](discord::Result result) {
        if (result != discord::Result::Ok) {
            // handle error
        }
    }
);
```

### C API (After)
```cpp
void DISCORD_CALLBACK UpdateActivityCallback(void* data, enum EDiscordResult result) {
    if (result != DiscordResult_Ok) {
        // handle error
    }
}

activities->update_activity(activities, &activity, nullptr, UpdateActivityCallback);
```

## Running Callbacks

### C++ API (Before)
```cpp
core->RunCallbacks();
```

### C API (After)
```cpp
core->run_callbacks(core);
```

## Header Include

### C++ API (Before)
```cpp
#include "discord/discord.h"
```

### C API (After)
```cpp
#pragma pack(push, 8)
#include "discord_game_sdk.h"
#pragma pack(pop)
```

Note: The `#pragma pack` directives are recommended in the Discord SDK documentation for compatibility with Unreal Engine 3 and older Visual Studio versions.

## Summary of Changes

| Aspect | C++ API | C API |
|--------|---------|-------|
| **Types** | `discord::Core*`, `discord::Activity` | `struct IDiscordCore*`, `struct DiscordActivity` |
| **Method Style** | Object methods: `obj.Method()` | Function pointers: `obj->method(obj, ...)` |
| **String Setting** | Methods: `SetState(str)` | Direct: `strncpy(member, str, 127)` |
| **Callbacks** | Lambda functions | C-style function pointers with `DISCORD_CALLBACK` |
| **Namespace** | `discord::` namespace | No namespace, struct-based |
| **Initialization** | `Core::Create()` | `DiscordCreate()` with params struct |
| **Header** | `discord/discord.h` | `discord_game_sdk.h` with pragma pack |

## Benefits

1. **Simpler Linking**: No need to compile C++ wrapper sources
2. **Better Compatibility**: Stable C ABI works with any compiler
3. **Explicit Memory**: Direct struct member access, no hidden allocations
4. **Standard Practice**: Follows common C API patterns
5. **Cross-Language**: Can be called from C, making it more flexible
