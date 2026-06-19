export type NativeAudioStatus = 'idle' | 'loading' | 'playing' | 'ended' | 'error';

export type NativeAudioOutputRoute =
  | 'builtin'
  | 'wired'
  | 'bluetooth'
  | 'usb'
  | 'hdmi'
  | 'other'
  | 'unknown';

export type NativeAudioState = {
  status: NativeAudioStatus;
  currentTime: number;
  duration: number;
  isPlaying: boolean;
  buffering: boolean;
  rate: number;
  /**
   * OS-reported audio output latency in seconds (route-aware where the OS exposes it).
   * 0 (or absent) means unknown. Combine with `outputRoute` to decide how to adjust
   * `currentTime`:
   *
   * - iOS: `outputLatency` is route-aware (includes Bluetooth). Subtract it from
   *   `currentTime` to get the time the user is hearing right now.
   * - Android, builtin/wired: `currentTime` is already audible-aligned (ExoPlayer's
   *   position tracker accounts for the AudioTrack latency). `outputLatency` is a
   *   small device-static buffer hint; consumers should *not* subtract it.
   * - Android, bluetooth: `currentTime` is NOT fully latency-adjusted — the BT A2DP
   *   codec + transport delay (~100-300ms typical) is invisible to the framework
   *   and not captured in `outputLatency`. Apply a fixed app-side correction.
   */
  outputLatency?: number;
  /**
   * Active audio output route. Use this to decide whether/how to compensate
   * `currentTime` for output latency (see `outputLatency` notes).
   */
  outputRoute?: NativeAudioOutputRoute;
  error?: string;
};

export type NativeAudioSetSourcePayload = {
  src: string;
  id?: number;
  title?: string;
  artist?: string;
  artworkUrl?: string;
};

export type NativeAudioProgressCheckpoint = {
  id: number;
  currentTime: number;
  updatedAtMs: number;
  status?: 'idle' | 'loading' | 'playing' | 'ended' | 'error';
};

export declare const initialize: () => Promise<NativeAudioState>;
export declare const setSource: (payload: NativeAudioSetSourcePayload) => Promise<NativeAudioState>;
export declare const play: () => Promise<NativeAudioState>;
export declare const pause: () => Promise<NativeAudioState>;
export declare const seekTo: (position: number) => Promise<NativeAudioState>;
export declare const setRate: (rate: number) => Promise<NativeAudioState>;
export declare const getState: () => Promise<NativeAudioState>;
export declare const getProgressCheckpoint: () => Promise<NativeAudioProgressCheckpoint | null>;
export declare const clearProgressCheckpoint: () => Promise<void>;
export declare const dispose: () => Promise<void>;
export declare const addStateListener: (handler: (state: NativeAudioState) => void) => Promise<() => void>;
