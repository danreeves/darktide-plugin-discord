const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{
        .default_target = .{
            .cpu_arch = .x86_64,
            .os_tag = .windows,
            .abi = .msvc,
        },
    });
    const optimize = b.standardOptimizeOption(.{});

    var lib = b.*.addLibrary(.{
        .name = "darktide_discord_pluginw64_release",
        .root_module = b.*.createModule(.{
            .target = target,
            .optimize = optimize,
        }),
        .linkage = .dynamic,
    });
    lib.linkLibC();
    lib.linkSystemLibrary("user32");
    lib.addCSourceFile(.{
        .file = b.path("src/darktide_discord.cpp"),
        .flags = &[_][]const u8{ "-std=c++17", "-fno-exceptions", "-fno-rtti" },
    });
    lib.addCSourceFile(.{
        .file = b.path("src/lua_helpers.cpp"),
        .flags = &[_][]const u8{ "-std=c++17", "-fno-exceptions", "-fno-rtti" },
    });
    lib.addCSourceFile(.{
        .file = b.path("src/lua_linkage.cpp"),
        .flags = &[_][]const u8{ "-std=c++17", "-fno-exceptions", "-fno-rtti" },
    });

    // Discord SDK wrapper implementations
    lib.addCSourceFile(.{
        .file = b.path("src/discord/achievement_manager.cpp"),
        .flags = &[_][]const u8{ "-std=c++17", "-fno-exceptions", "-fno-rtti" },
    });
    lib.addCSourceFile(.{
        .file = b.path("src/discord/activity_manager.cpp"),
        .flags = &[_][]const u8{ "-std=c++17", "-fno-exceptions", "-fno-rtti" },
    });
    lib.addCSourceFile(.{
        .file = b.path("src/discord/application_manager.cpp"),
        .flags = &[_][]const u8{ "-std=c++17", "-fno-exceptions", "-fno-rtti" },
    });
    lib.addCSourceFile(.{
        .file = b.path("src/discord/core.cpp"),
        .flags = &[_][]const u8{ "-std=c++17", "-fno-exceptions", "-fno-rtti" },
    });
    lib.addCSourceFile(.{
        .file = b.path("src/discord/image_manager.cpp"),
        .flags = &[_][]const u8{ "-std=c++17", "-fno-exceptions", "-fno-rtti" },
    });
    lib.addCSourceFile(.{
        .file = b.path("src/discord/lobby_manager.cpp"),
        .flags = &[_][]const u8{ "-std=c++17", "-fno-exceptions", "-fno-rtti" },
    });
    lib.addCSourceFile(.{
        .file = b.path("src/discord/network_manager.cpp"),
        .flags = &[_][]const u8{ "-std=c++17", "-fno-exceptions", "-fno-rtti" },
    });
    lib.addCSourceFile(.{
        .file = b.path("src/discord/overlay_manager.cpp"),
        .flags = &[_][]const u8{ "-std=c++17", "-fno-exceptions", "-fno-rtti" },
    });
    lib.addCSourceFile(.{
        .file = b.path("src/discord/relationship_manager.cpp"),
        .flags = &[_][]const u8{ "-std=c++17", "-fno-exceptions", "-fno-rtti" },
    });
    lib.addCSourceFile(.{
        .file = b.path("src/discord/storage_manager.cpp"),
        .flags = &[_][]const u8{ "-std=c++17", "-fno-exceptions", "-fno-rtti" },
    });
    lib.addCSourceFile(.{
        .file = b.path("src/discord/store_manager.cpp"),
        .flags = &[_][]const u8{ "-std=c++17", "-fno-exceptions", "-fno-rtti" },
    });
    lib.addCSourceFile(.{
        .file = b.path("src/discord/types.cpp"),
        .flags = &[_][]const u8{ "-std=c++17", "-fno-exceptions", "-fno-rtti" },
    });
    lib.addCSourceFile(.{
        .file = b.path("src/discord/user_manager.cpp"),
        .flags = &[_][]const u8{ "-std=c++17", "-fno-exceptions", "-fno-rtti" },
    });
    lib.addCSourceFile(.{
        .file = b.path("src/discord/voice_manager.cpp"),
        .flags = &[_][]const u8{ "-std=c++17", "-fno-exceptions", "-fno-rtti" },
    });

    lib.addIncludePath(b.path("src"));
    lib.addIncludePath(b.path("src/lua"));
    lib.addIncludePath(b.path("discord_game_sdk"));
    lib.addIncludePath(b.path("discord_game_sdk/cpp"));
    lib.addIncludePath(b.path("discord_game_sdk/c"));

    // Select Discord SDK library path based on target architecture
    const discord_lib_subdir = switch (target.result.cpu.arch) {
        .x86 => "x86",
        .x86_64 => "x86_64",
        .aarch64 => "aarch64",
        else => "x86_64",
    };
    const discord_lib_path = b.fmt("discord_game_sdk/lib/{s}", .{discord_lib_subdir});

    lib.addLibraryPath(b.path(discord_lib_path));
    lib.addObjectFile(b.path(b.fmt("discord_game_sdk/lib/{s}/discord_game_sdk.dll.lib", .{discord_lib_subdir})));

    b.*.installArtifact(lib);
}
