const std = @import("std");

pub fn build(b: *std.Build) void {
    // Cross-compile for Windows x86_64
    const target = b.resolveTargetQuery(.{
        .cpu_arch = .x86_64,
        .os_tag = .windows,
        .abi = .gnu,
    });
    const optimize = b.standardOptimizeOption(.{});

    // Compile Discord SDK C++ files into a static library
    const discord_lib = b.addLibrary(.{
        .name = "discord_sdk",
        .linkage = .static,
        .root_module = b.createModule(.{
            .target = target,
            .optimize = optimize,
        }),
    });
    
    // Add Discord SDK C++ sources
    discord_lib.addCSourceFiles(.{
        .files = &.{
            "src/discord/achievement_manager.cpp",
            "src/discord/activity_manager.cpp",
            "src/discord/application_manager.cpp",
            "src/discord/core.cpp",
            "src/discord/image_manager.cpp",
            "src/discord/lobby_manager.cpp",
            "src/discord/network_manager.cpp",
            "src/discord/overlay_manager.cpp",
            "src/discord/relationship_manager.cpp",
            "src/discord/storage_manager.cpp",
            "src/discord/store_manager.cpp",
            "src/discord/user_manager.cpp",
            "src/discord/voice_manager.cpp",
        },
        .flags = &.{ "-std=c++11" },
    });
    discord_lib.addIncludePath(b.path("src/discord"));
    discord_lib.linkLibCpp();
    discord_lib.linkLibC();
    
    // Main plugin library
    const lib = b.addLibrary(.{
        .name = "darktide_discord_pluginw64",
        .linkage = .dynamic,
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/darktide_discord.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });

    // Add include paths for external libraries
    lib.root_module.addIncludePath(b.path("src"));
    lib.root_module.addIncludePath(b.path("src/lua"));
    lib.root_module.addIncludePath(b.path("src/discord"));

    // Link Discord SDK static library
    lib.linkLibrary(discord_lib);
    
    // Link Discord Game SDK DLL
    lib.root_module.addLibraryPath(b.path("discord"));
    lib.root_module.linkSystemLibrary("discord_game_sdk.dll", .{});

    // Link standard C library
    lib.linkLibC();
    lib.linkLibCpp();

    b.installArtifact(lib);
}
