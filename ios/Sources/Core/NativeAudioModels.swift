import Foundation

let nativeAudioStateEvent = "native_audio_state"
let remoteSeekStepSeconds = 10.0
let checkpointDefaultsKeyV1 = "tauri_native_audio_progress_checkpoint_v1"

struct NativeAudioState: Encodable, Sendable {
  let status: String
  let currentTime: Double
  let duration: Double
  let isPlaying: Bool
  let buffering: Bool
  let rate: Double
  // OS-reported audio output latency in seconds (route-aware). 0 means unknown.
  let outputLatency: Double
  // Active audio output route. One of: "builtin", "wired", "bluetooth", "usb",
  // "hdmi", "other", "unknown". Consumers use this together with `outputLatency`
  // to decide whether to subtract latency from `currentTime` and how much.
  let outputRoute: String
  let error: String?
}

struct NativeAudioProgressCheckpoint: Codable, Sendable {
  let id: Int64
  let currentTime: Double
  let updatedAtMs: Int64
  let status: String?
}

struct SetSourceArgs: Decodable, Sendable {
  let src: String
  let id: Int64?
  let title: String?
  let artist: String?
  let artworkUrl: String?
}

struct SeekToArgs: Decodable, Sendable {
  let position: Double?
}

struct SetRateArgs: Decodable, Sendable {
  let rate: Double?
}

enum NativeAudioRuntimeError: LocalizedError {
  case invalidSource
  case invalidRate

  var errorDescription: String? {
    switch self {
    case .invalidSource:
      return "invalid source"
    case .invalidRate:
      return "rate must be > 0"
    }
  }
}

struct PlaybackMetadata: Sendable {
  let title: String?
  let artist: String?
  let artworkURL: String?
}

struct RuntimeSnapshot: Sendable {
  let sourceRevision: Int64
  let seekRevision: Int64
  let state: NativeAudioState
}
