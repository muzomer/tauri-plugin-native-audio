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
];

fn main() {
    tauri_plugin::Builder::new(COMMANDS)
        .android_path("android")
        .ios_path("ios")
        .build();
}
