const std = @import("std");

pub fn build(b: *std.Build) void {
    // Cross-compile for Windows x86_64
    const target = b.resolveTargetQuery(.{
        .cpu_arch = .x86_64,
        .os_tag = .windows,
        .abi = .gnu,
    });
    const optimize = b.standardOptimizeOption(.{});

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
    lib.root_module.addIncludePath(b.path("discord_game_sdk/c"));

    // Link Discord Game SDK DLL
    lib.root_module.addLibraryPath(b.path("discord_game_sdk/lib/x86_64"));
    lib.root_module.linkSystemLibrary("discord_game_sdk", .{});

    // Link standard C library
    lib.linkLibC();

    b.installArtifact(lib);
}
