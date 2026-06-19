const COMMANDS: &[&str] = &[
    "initialize",
    "set_source",
    "play",
    "pause",
    "seek_to",
    "set_rate",
    "get_state",
    "get_progress_checkpoint",
    "clear_progress_checkpoint",
    "dispose",
    "register_listener",
    "remove_listener",
];

fn main() {
    tauri_plugin::Builder::new(COMMANDS)
        .android_path("android")
        .ios_path("ios")
        .build();
}
