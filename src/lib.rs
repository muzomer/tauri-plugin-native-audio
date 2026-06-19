use tauri::{
    plugin::{Builder, TauriPlugin},
    Runtime,
};

#[cfg(target_os = "android")]
const PLUGIN_IDENTIFIER: &str = "app.tauri.nativeaudio";

#[cfg(target_os = "ios")]
tauri::ios_plugin_binding!(init_plugin_native_audio);

// On mobile (iOS/Android) the plugin commands are handled entirely by the native
// plugin registered in `setup` below, so no Rust `invoke_handler` is needed.
//
// On desktop there is no native audio backend. Without these stubs every
// `invoke('plugin:native-audio|...')` would reject with "command not found", which
// breaks `tauri dev` on a developer machine. The stubs return a benign idle state so
// the app degrades gracefully instead of hard-rejecting.
#[cfg(not(any(target_os = "android", target_os = "ios")))]
mod desktop_stub {
    use serde_json::{json, Value};

    fn idle_state() -> Value {
        json!({
            "status": "idle",
            "currentTime": 0.0,
            "duration": 0.0,
            "isPlaying": false,
            "buffering": false,
            "rate": 1.0,
            "outputLatency": 0.0,
        })
    }

    #[tauri::command]
    pub fn initialize() -> Value {
        idle_state()
    }

    #[tauri::command]
    pub fn set_source() -> Value {
        idle_state()
    }

    #[tauri::command]
    pub fn play() -> Value {
        idle_state()
    }

    #[tauri::command]
    pub fn pause() -> Value {
        idle_state()
    }

    #[tauri::command]
    pub fn seek_to() -> Value {
        idle_state()
    }

    #[tauri::command]
    pub fn set_rate() -> Value {
        idle_state()
    }

    #[tauri::command]
    pub fn get_state() -> Value {
        idle_state()
    }

    #[tauri::command]
    pub fn get_progress_checkpoint() -> Option<Value> {
        None
    }

    #[tauri::command]
    pub fn clear_progress_checkpoint() {}

    #[tauri::command]
    pub fn dispose() {}
}

pub fn init<R: Runtime>() -> TauriPlugin<R> {
    let builder = Builder::new("native-audio");

    #[cfg(not(any(target_os = "android", target_os = "ios")))]
    let builder = builder.invoke_handler(tauri::generate_handler![
        desktop_stub::initialize,
        desktop_stub::set_source,
        desktop_stub::play,
        desktop_stub::pause,
        desktop_stub::seek_to,
        desktop_stub::set_rate,
        desktop_stub::get_state,
        desktop_stub::get_progress_checkpoint,
        desktop_stub::clear_progress_checkpoint,
        desktop_stub::dispose,
    ]);

    builder
        .setup(|_app, _api| {
            #[cfg(target_os = "android")]
            {
                let _ = _api.register_android_plugin(PLUGIN_IDENTIFIER, "NativeAudioPlugin")?;
            }
            #[cfg(target_os = "ios")]
            {
                let _ = _api.register_ios_plugin(init_plugin_native_audio)?;
            }
            Ok(())
        })
        .build()
}
