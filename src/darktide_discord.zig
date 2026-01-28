const std = @import("std");

// Import C headers with proper configuration
const c = @cImport({
    @cDefine("_STDDEF_H", "1");
    @cInclude("stddef.h");
    @cInclude("time.h");
    @cInclude("PluginApi128.h");
    @cInclude("discord/discord.h");
});

var core: ?*c.discord_Core = null;
var activity: c.discord_Activity = undefined;
var lua_api: ?*c.LuaApi128 = null;
var logger: ?*c.LoggingApi = null;

fn set_state(L: ?*c.lua_State) callconv(.c) c_int {
    if (lua_api.?.isstring.?(L, 1) != 0) {
        const value = lua_api.?.tolstring.?(L, 1, null);
        c.discord_Activity_SetState(&activity, value);
        lua_api.?.pushboolean.?(L, 1); // success
    } else {
        lua_api.?.pushboolean.?(L, 0); // error
    }
    return 1;
}

fn set_details(L: ?*c.lua_State) callconv(.c) c_int {
    if (lua_api.?.isstring.?(L, 1) != 0) {
        const value = lua_api.?.tolstring.?(L, 1, null);
        c.discord_Activity_SetDetails(&activity, value);
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
        var assets = c.discord_Activity_GetAssets(&activity);
        c.discord_ActivityAssets_SetSmallImage(assets, archetype);
        c.discord_ActivityAssets_SetSmallText(assets, details);
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
        var party = c.discord_Activity_GetParty(&activity);
        var size = c.discord_ActivityParty_GetSize(party);
        c.discord_PartySize_SetCurrentSize(size, current_size);
        c.discord_PartySize_SetMaxSize(size, max_size);
        lua_api.?.pushboolean.?(L, 1); // success
    } else {
        lua_api.?.pushboolean.?(L, 0); // error
    }
    return 1;
}

fn set_start_time(L: ?*c.lua_State) callconv(.c) c_int {
    const result = c.time(null);
    var timestamps = c.discord_Activity_GetTimestamps(&activity);
    c.discord_ActivityTimestamps_SetStart(timestamps, result);
    lua_api.?.pushboolean.?(L, 1); // success
    return 1;
}

fn update_discord() void {
    if (core) |discord_core| {
        const activity_manager = c.discord_Core_GetActivityManager(discord_core);
        c.discord_ActivityManager_UpdateActivity(
            activity_manager,
            &activity,
            null,
            updateActivityCallback,
        );
    }
}

fn updateActivityCallback(callback_data: ?*anyopaque, result: c.discord_Result) callconv(.c) void {
    _ = callback_data;
    if (result != c.discord_Result_Ok) {
        var message: [255]u8 = undefined;
        const msg = std.fmt.bufPrintZ(&message, "non-zero update result: {d}", .{result}) catch return;
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

    const client_id: i64 = 1111429477055090698;
    var temp_core: ?*c.discord_Core = null;
    const result = c.discord_Core_Create(client_id, c.DiscordCreateFlags_NoRequireDiscord, &temp_core);
    _ = result;
    core = temp_core;

    activity = std.mem.zeroes(c.discord_Activity);
    var assets = c.discord_Activity_GetAssets(&activity);
    c.discord_ActivityAssets_SetLargeImage(assets, "darktide");
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
        _ = c.discord_Core_RunCallbacks(discord_core);
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
