# Building with Zig

This project is now built entirely with Zig. All C++ code has been removed.

## Quick Start

### Install Zig

Download Zig from: https://ziglang.org/download/

Recommended version: **0.13.0** or later

### Build the Project

```bash
zig build
```

The DLL will be output to: `zig-out/lib/darktide_discord_pluginw64.dll`

### Build Options

```bash
# Debug build (default)
zig build

# Release build (optimized, smaller binary)
zig build -Doptimize=ReleaseFast

# Release with safety checks
zig build -Doptimize=ReleaseSafe

# Smallest binary
zig build -Doptimize=ReleaseSmall
```

## GitHub Actions

The repository includes a GitHub Actions workflow that automatically builds the project when you push changes.

**Workflow file:** `.github/workflows/copilot-setup-steps.yml`

**What it does:**
1. Sets up Zig 0.13.0
2. Builds the project with `zig build`
3. Uploads the DLL as an artifact

**Triggers:**
- Push to `main` or `copilot/**` branches
- Pull requests
- Manual trigger via `workflow_dispatch`

**Artifacts:**
After a successful build, download the DLL from the Actions tab:
1. Go to the Actions tab in GitHub
2. Click on the latest workflow run
3. Download the `darktide_discord_pluginw64` artifact

## Cross-Compilation

Zig includes built-in cross-compilation support. The build is configured to target Windows x86_64 automatically.

You can build from:
- ✅ Linux
- ✅ macOS
- ✅ Windows

No additional setup needed - Zig handles everything!

## Project Structure

```
darktide-plugin-discord/
├── src/
│   ├── darktide_discord.zig    # Main implementation (Zig)
│   ├── PluginApi128.h           # Stingray Plugin API
│   ├── lua/                     # Lua headers
│   └── lua_helpers.h            # Lua helper definitions
├── discord_game_sdk/            # Discord SDK
│   ├── c/                       # C headers
│   └── lib/x86_64/             # Libraries
├── build.zig                    # Build configuration
└── .github/workflows/           # CI/CD
    └── copilot-setup-steps.yml # Zig build workflow
```

## Implementation Details

The Zig implementation:

- **Direct C interop**: Uses `@cImport` to import C headers
- **Type safe**: Zig's type system catches errors at compile time
- **No external dependencies**: Everything needed is in the repo
- **Single binary output**: One DLL, no runtime dependencies

### Key features:

```zig
// Import C headers directly
const c = @cImport({
    @cInclude("PluginApi128.h");
    @cInclude("discord_game_sdk.h");
});

// Export DLL entry point
export fn get_plugin_api(api: c_uint) ?*anyopaque {
    // Implementation
}
```

## Troubleshooting

### Zig not found

Make sure Zig is in your PATH:

```bash
# Check Zig installation
zig version

# Add to PATH (Linux/Mac)
export PATH=$PATH:/path/to/zig

# Add to PATH (Windows)
set PATH=%PATH%;C:\path\to\zig
```

### Build fails

1. Check Zig version: `zig version` (should be 0.13.0+)
2. Clean build cache: `rm -rf zig-cache zig-out`
3. Try again: `zig build`

### DLL not found after build

Check the output directory:
```bash
ls -la zig-out/lib/
```

The DLL should be: `zig-out/lib/darktide_discord_pluginw64.dll`

## Migration from C++

This project was migrated from C++ to Zig. See `MIGRATION_COMPLETE.md` for details.

**Benefits of Zig:**
- ✅ No C++ compiler needed
- ✅ Built-in cross-compilation
- ✅ Simpler build process
- ✅ Better type safety
- ✅ Direct C interop
- ✅ Smaller, faster binaries

## Contributing

When contributing, please:
1. Install Zig 0.13.0 or later
2. Test your changes with `zig build`
3. Verify the DLL builds successfully
4. Check the GitHub Actions workflow passes

All C++ code has been removed. Only contribute Zig code from now on.
