# NOTE: This Makefile is deprecated. Use `zig build` instead.
# Kept for reference only.

# Compiler
CXX = g++

# Compiler flags
CXXFLAGS = -Wall -Wextra -std=c++11 -shared -Os -I./src/lua -I./discord_game_sdk/c

# Linker flags
LDFLAGS = -L./discord_game_sdk/lib/x86_64

# Libraries to link against
LDLIBS = -ldiscord_game_sdk

# Target DLL name
TARGET = darktide_discord_pluginw64.dll

# Source file (C++ version - now replaced by Zig implementation)
SRC = src/darktide_discord.cpp

all:
	@echo "ERROR: This Makefile is deprecated."
	@echo "The project has been migrated to Zig."
	@echo ""
	@echo "To build, use:"
	@echo "  zig build"
	@echo ""
	@echo "The DLL will be output to: zig-out/lib/darktide_discord_pluginw64.dll"
	@exit 1

clean:
	rm -rf zig-out zig-cache
	del /F /Q "$(TARGET)" 2>/dev/null || true
