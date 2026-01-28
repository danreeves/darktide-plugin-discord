const std = @import("std");

// Import C headers with proper configuration
const c = @cImport({
    @cDefine("_STDDEF_H", "1");
    @cInclude("stddef.h");
    @cInclude("time.h");
    @cInclude("PluginApi128.h");
    @cInclude("discord_game_sdk.h");
});

// Application state
var core: ?*c.struct_IDiscordCore = null;
var activities: ?*c.struct_IDiscordActivityManager = null;
var activity: c.struct_DiscordActivity = undefined;
var lua_api: ?*c.LuaApi128 = null;
var logger: ?*c.LoggingApi = null;

fn set_state(L: ?*c.lua_State) callconv(.c) c_int {
    if (lua_api.?.isstring.?(L, 1) != 0) {
        const value = lua_api.?.tolstring.?(L, 1, null);
        // Copy state string (max 128 chars)
        const state_ptr: [*c]u8 = @ptrCast(@constCast(&activity.state));
        var i: usize = 0;
        while (value[i] != 0 and i < 127) : (i += 1) {
            state_ptr[i] = value[i];
        }
        state_ptr[i] = 0;
        lua_api.?.pushboolean.?(L, 1); // success
    } else {
        lua_api.?.pushboolean.?(L, 0); // error
    }
    return 1;
}

fn set_details(L: ?*c.lua_State) callconv(.c) c_int {
    if (lua_api.?.isstring.?(L, 1) != 0) {
        const value = lua_api.?.tolstring.?(L, 1, null);
        // Copy details string (max 128 chars)
        const details_ptr: [*c]u8 = @ptrCast(@constCast(&activity.details));
        var i: usize = 0;
        while (value[i] != 0 and i < 127) : (i += 1) {
            details_ptr[i] = value[i];
        }
        details_ptr[i] = 0;
        lua_api.?.pushboolean.?(L, 1); // success
    } else {
        lua_api.?.pushboolean.?(L, 0); // error
    }
    return 1;
}

fn set_class(L: ?*c.lua_State) callconv(.c) c_int {
    if (lua_api.?.isstring.?(L, 1) != 0 and lua_api.?.isstring.?(L, 2) != 0) {
        const archetype = lua_api.?.tolstring.?(L, 1, null);
        const details = lua_api.?.tolstring.?(L, 2, null);
        
        // Copy small image string (max 128 chars)
        const small_image_ptr: [*c]u8 = @ptrCast(@constCast(&activity.assets.small_image));
        var i: usize = 0;
        while (archetype[i] != 0 and i < 127) : (i += 1) {
            small_image_ptr[i] = archetype[i];
        }
        small_image_ptr[i] = 0;
        
        // Copy small text string (max 128 chars)
        const small_text_ptr: [*c]u8 = @ptrCast(@constCast(&activity.assets.small_text));
        i = 0;
        while (details[i] != 0 and i < 127) : (i += 1) {
            small_text_ptr[i] = details[i];
        }
        small_text_ptr[i] = 0;
        
        lua_api.?.pushboolean.?(L, 1); // success
    } else {
        lua_api.?.pushboolean.?(L, 0); // error
    }
    return 1;
}

fn set_party_size(L: ?*c.lua_State) callconv(.c) c_int {
    if (lua_api.?.isnumber.?(L, 1) != 0 and lua_api.?.isnumber.?(L, 2) != 0) {
        const current_size: i32 = @intFromFloat(lua_api.?.tonumber.?(L, 1));
        const max_size: i32 = @intFromFloat(lua_api.?.tonumber.?(L, 2));
        activity.party.size.current_size = current_size;
        activity.party.size.max_size = max_size;
        lua_api.?.pushboolean.?(L, 1); // success
    } else {
        lua_api.?.pushboolean.?(L, 0); // error
    }
    return 1;
}

fn set_start_time(L: ?*c.lua_State) callconv(.c) c_int {
    const result = c.time(null);
    activity.timestamps.start = result;
    lua_api.?.pushboolean.?(L, 1); // success
    return 1;
}

fn update_discord() void {
    if (activities) |act_mgr| {
        _ = act_mgr.update_activity.?(act_mgr, &activity, null, updateActivityCallback);
    }
}

fn updateActivityCallback(callback_data: ?*anyopaque, result: c.enum_EDiscordResult) callconv(.c) void {
    _ = callback_data;
    if (result != c.DiscordResult_Ok) {
        var message: [255]u8 = undefined;
        const msg = std.fmt.bufPrintZ(&message, "non-zero update result: {d}", .{@intFromEnum(result)}) catch return;
        if (logger) |log| {
            log.info.?("DarktideDiscord", msg.ptr);
        }
    }
}

fn lua_update(L: ?*c.lua_State) callconv(.c) c_int {
    _ = L;
    update_discord();
    return 0;
}

fn setup_game(get_engine_api: c.GetApiFunction) callconv(.c) void {
    lua_api = @ptrCast(@alignCast(get_engine_api.?(c.LUA_API_ID)));
    logger = @ptrCast(@alignCast(get_engine_api.?(c.LOGGING_API_ID)));

    const lua = lua_api.?;
    lua.set_module_number.?("DarktideDiscord", "VERSION", 1);
    lua.add_module_function.?("DarktideDiscord", "set_state", set_state);
    lua.add_module_function.?("DarktideDiscord", "set_details", set_details);
    lua.add_module_function.?("DarktideDiscord", "set_class", set_class);
    lua.add_module_function.?("DarktideDiscord", "set_party_size", set_party_size);
    lua.add_module_function.?("DarktideDiscord", "set_start_time", set_start_time);
    lua.add_module_function.?("DarktideDiscord", "update", lua_update);

    // Initialize Discord SDK
    var params: c.struct_DiscordCreateParams = undefined;
    c.DiscordCreateParamsSetDefault(&params);
    params.client_id = 1111429477055090698;
    params.flags = c.DiscordCreateFlags_NoRequireDiscord;
    params.event_data = null;
    
    var temp_core: ?*c.struct_IDiscordCore = null;
    const result = c.DiscordCreate(c.DISCORD_VERSION, &params, &temp_core);
    _ = result;
    core = temp_core;

    // Get activity manager
    if (core) |discord_core| {
        activities = discord_core.get_activity_manager.?(discord_core);
    }

    // Initialize activity
    activity = std.mem.zeroes(c.struct_DiscordActivity);
    
    // Set large image
    const large_image_ptr: [*c]u8 = @ptrCast(@constCast(&activity.assets.large_image));
    const large_image = "darktide";
    var i: usize = 0;
    while (i < large_image.len) : (i += 1) {
        large_image_ptr[i] = large_image[i];
    }
    large_image_ptr[i] = 0;
    
    update_discord();
}

fn get_name() callconv(.c) [*c]const u8 {
    return "DarktideDiscord";
}

fn loaded(_: c.GetApiFunction) callconv(.c) void {
    // Nothing to do here
}

fn update_game(_: f32) callconv(.c) void {
    if (core) |discord_core| {
        _ = discord_core.run_callbacks.?(discord_core);
    }
}

fn shutdown_game() callconv(.c) void {}

export fn get_plugin_api(api: c_uint) ?*anyopaque {
    if (api == c.PLUGIN_API_ID) {
        const plugin_api = struct {
            var api_instance: c.PluginApi128 = c.PluginApi128{
                .version = 65,
                .flags = 3,
                .loaded = loaded,
                .start_reload = null,
                .unloaded = null,
                .finish_reload = null,
                .setup_resources = null,
                .shutdown_resources = null,
                .setup_game = setup_game,
                .update_game = update_game,
                .shutdown_game = @ptrCast(&shutdown_game),
                .unregister_world = null,
                .register_world = null,
                .get_hash = null,
                .get_name = @ptrCast(&get_name),
                .unkfunc13 = null,
                .unkfunc14 = null,
                .unkfunc15 = null,
            };
        };
        return @ptrCast(&plugin_api.api_instance);
    }
    return null;
}
