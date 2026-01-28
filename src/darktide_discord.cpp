#include <ctime>
#include <cstring>
#include <cstdio>

#include "PluginApi128.h"

// Use #pragma pack as recommended in the Discord SDK C documentation
#pragma pack(push, 8)
#include "discord_game_sdk.h"
#pragma pack(pop)

#include "lua.h"

// Application state
struct IDiscordCore* core = nullptr;
struct IDiscordActivityManager* activities = nullptr;
struct DiscordActivity activity;

LuaApi128* lua = nullptr;
LoggingApi* logger = nullptr;

// Callback for activity updates
void DISCORD_CALLBACK UpdateActivityCallback(void* data, enum EDiscordResult result) {
  if (result != DiscordResult_Ok) {
    char message[255] = "";
    snprintf(message, sizeof(message), "non-zero update result: %d", (int)result);
    if (logger) {
      logger->info("DarktideDiscord", message);
    }
  }
}

static int set_state(lua_State* L) {
  if (lua->isstring(L, 1)) {
    const char* value = lua->tolstring(L, 1, nullptr);
    // Copy to activity.state (max 128 chars)
    strncpy(activity.state, value, 127);
    activity.state[127] = '\0';
    lua->pushboolean(L, 1);  // success
  } else {
    lua->pushboolean(L, 0);  // error
  }
  return 1;
}

static int set_details(lua_State* L) {
  if (lua->isstring(L, 1)) {
    const char* value = lua->tolstring(L, 1, nullptr);
    // Copy to activity.details (max 128 chars)
    strncpy(activity.details, value, 127);
    activity.details[127] = '\0';
    lua->pushboolean(L, 1);  // success
  } else {
    lua->pushboolean(L, 0);  // error
  }
  return 1;
}

static int set_class(lua_State* L) {
  if (lua->isstring(L, 1) && lua->isstring(L, 2)) {
    const char* archetype = lua->tolstring(L, 1, nullptr);
    const char* details = lua->tolstring(L, 2, nullptr);
    // Copy to activity.assets
    strncpy(activity.assets.small_image, archetype, 127);
    activity.assets.small_image[127] = '\0';
    strncpy(activity.assets.small_text, details, 127);
    activity.assets.small_text[127] = '\0';
    lua->pushboolean(L, 1);  // success
  } else {
    lua->pushboolean(L, 0);  // error
  }
  return 1;
}

static int set_party_size(lua_State* L) {
  if (lua->isnumber(L, 1) && lua->isnumber(L, 2)) {
    int current_size = (int)lua->tonumber(L, 1);
    int max_size = (int)lua->tonumber(L, 2);
    activity.party.size.current_size = current_size;
    activity.party.size.max_size = max_size;
    lua->pushboolean(L, 1);  // success
  } else {
    lua->pushboolean(L, 0);  // error
  }
  return 1;
}

static int set_start_time(lua_State* L) {
  time_t result = time(nullptr);
  activity.timestamps.start = result;
  lua->pushboolean(L, 1);  // success
  return 1;
}

static void update() {
  if (activities) {
    activities->update_activity(activities, &activity, nullptr, UpdateActivityCallback);
  }
}

static int lua_update(lua_State* L) {
  update();
  return 0;
}

static void setup_game(GetApiFunction get_engine_api) {
  lua = (LuaApi128*)get_engine_api(LUA_API_ID);
  logger = (LoggingApi*)get_engine_api(LOGGING_API_ID);

  lua->set_module_number("DarktideDiscord", "VERSION", 1);
  lua->add_module_function("DarktideDiscord", "set_state", set_state);
  lua->add_module_function("DarktideDiscord", "set_details", set_details);
  lua->add_module_function("DarktideDiscord", "set_class", set_class);
  lua->add_module_function("DarktideDiscord", "set_party_size", set_party_size);
  lua->add_module_function("DarktideDiscord", "set_start_time", set_start_time);
  lua->add_module_function("DarktideDiscord", "update", lua_update);

  // Initialize Discord SDK using C API
  struct DiscordCreateParams params;
  DiscordCreateParamsSetDefault(&params);
  params.client_id = 1111429477055090698;
  params.flags = DiscordCreateFlags_NoRequireDiscord;
  params.event_data = nullptr;
  
  enum EDiscordResult result = DiscordCreate(DISCORD_VERSION, &params, &core);
  if (result == DiscordResult_Ok && core) {
    // Get the activity manager
    activities = core->get_activity_manager(core);
    
    // Initialize activity
    memset(&activity, 0, sizeof(activity));
    strncpy(activity.assets.large_image, "darktide", 127);
    activity.assets.large_image[127] = '\0';
    
    update();
  }
}

static const char* get_name() { 
  return "DarktideDiscord"; 
}

static void loaded(GetApiFunction get_engine_api) {
  // Nothing to do
}

static void update(float dt) {
  if (core) {
    core->run_callbacks(core);
  }
}

static void shutdown() {
  // Cleanup if needed
}

extern "C" {
void* get_dynamic_plugin_api(unsigned api) {
  if (api == PLUGIN_API_ID) {
    static PluginApi128 api{};
    api.get_name = get_name;
    api.setup_game = setup_game;
    api.loaded = loaded;
    api.update_game = update;
    api.shutdown_game = shutdown;
    return &api;
  }
  return nullptr;
}

#if !defined STATIC_PLUGIN_LINKING
PLUGIN_DLLEXPORT void* get_plugin_api(unsigned api) {
  return get_dynamic_plugin_api(api);
}
#endif
}
