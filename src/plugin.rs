use crate::stingray_sdk::{lua_State, GetApiFunction, LoggingApi, LuaApi};
use crate::{MyEventHandler, PLUGIN_NAME};
use discord_game_sdk::{Activity, CreateFlags, Discord, EventHandler};

impl EventHandler for MyEventHandler {}
pub(crate) struct Plugin<'a> {
    pub log: LoggingApi,
    pub lua: LuaApi,
    pub discord: Discord<'a, MyEventHandler>,
}

extern "C" fn l_set_state(_l: *mut lua_State) -> i32 {
    0
}
extern "C" fn l_set_details(_l: *mut lua_State) -> i32 {
    0
}
extern "C" fn l_set_class(_l: *mut lua_State) -> i32 {
    0
}
extern "C" fn l_set_party_size(_l: *mut lua_State) -> i32 {
    0
}
extern "C" fn l_set_start_time(_l: *mut lua_State) -> i32 {
    0
}
extern "C" fn l_update(_l: *mut lua_State) -> i32 {
    0
}

impl<'a> Plugin<'a> {
    pub fn new(get_engine_api: GetApiFunction) -> Self {
        let log = LoggingApi::get(get_engine_api);
        let lua = LuaApi::get(get_engine_api);
        let mut discord =
            Discord::with_create_flags(1111429477055090698, CreateFlags::NoRequireDiscord).unwrap();
        *discord.event_handler_mut() = Some(MyEventHandler {});

        discord.update_activity(
            &Activity::empty()
                .with_large_image_key("darktide")
                .with_start_time(chrono::Utc::now().timestamp()),
            |_discord, result| {
                if let Err(error) = result {
                    // log.info(PLUGIN_NAME, format!("failed to update activity: {}", error));
                }
            },
        );

        Self { log, lua, discord }
    }

    pub fn setup_game(&self) {
        self.log
            .info(PLUGIN_NAME, format!("[setup_game] Initialising"));

        self.lua
            .set_module_number("DarktideDiscord", "VERSION", 2.0);
        self.lua
            .add_module_function("DarktideDiscord", "set_state", l_set_state);
        self.lua
            .add_module_function("DarktideDiscord", "set_details", l_set_details);
        self.lua
            .add_module_function("DarktideDiscord", "set_class", l_set_class);
        self.lua
            .add_module_function("DarktideDiscord", "set_party_size", l_set_party_size);
        self.lua
            .add_module_function("DarktideDiscord", "set_start_time", l_set_start_time);
        self.lua
            .add_module_function("DarktideDiscord", "update", l_update);
    }

    pub fn update_game(&mut self, _dt: f32) {
        match self.discord.run_callbacks() {
            Ok(_) => {}
            Err(e) => {
                self.log.error(PLUGIN_NAME, format!("[update_game] {}", e));
            }
        }
    }

    pub fn shutdown_game(&self) {
        self.log.info(PLUGIN_NAME, "[shutdown_game] Shutting down");
    }
}

impl<'a> std::fmt::Debug for Plugin<'a> {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        f.write_str("PluginApi")
    }
}
