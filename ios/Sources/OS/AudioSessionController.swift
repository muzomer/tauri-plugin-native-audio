import AVFoundation
import Foundation
import UIKit

enum AudioSessionEvent: Sendable {
  case interruptionBegan
  case interruptionEnded(shouldResume: Bool)
  case oldDeviceUnavailable
  case routeChanged
}

final class AudioSessionController {
  private var interruptionObserver: NSObjectProtocol?
  private var routeChangeObserver: NSObjectProtocol?
  private var eventHandler: ((AudioSessionEvent) -> Void)?

  deinit {
    unregisterObservers()
  }

  func configurePlaybackCategory() throws {
    try onMain {
      let session = AVAudioSession.sharedInstance()
      try session.setCategory(.playback, mode: .default, options: [])
    }
  }

  /// OS-reported audio output latency in seconds. Route-aware (updates for Bluetooth,
  /// AirPods, etc.). Returns 0 when unknown — e.g. the session is not active yet, in
  /// which case `AVAudioSession` reports 0.
  func outputLatencySeconds() -> Double {
    onMain {
      let latency = AVAudioSession.sharedInstance().outputLatency
      guard latency.isFinite, latency >= 0 else {
        return 0.0
      }
      return latency
    }
  }

  /// Active audio output route, derived from `AVAudioSession.currentRoute.outputs`.
  /// Returns one of "builtin", "wired", "bluetooth", "usb", "hdmi", "other", "unknown".
  func outputRoute() -> String {
    onMain {
      let outputs = AVAudioSession.sharedInstance().currentRoute.outputs
      guard let portType = outputs.first?.portType else {
        return "unknown"
      }
      switch portType {
      case .builtInSpeaker, .builtInReceiver:
        return "builtin"
      case .headphones, .lineOut:
        return "wired"
      case .bluetoothA2DP, .bluetoothLE, .bluetoothHFP:
        return "bluetooth"
      case .usbAudio:
        return "usb"
      case .HDMI:
        return "hdmi"
      case .carAudio, .airPlay:
        return "other"
      default:
        return "unknown"
      }
    }
  }

  func setActive(_ active: Bool) throws {
    try onMain {
      let session = AVAudioSession.sharedInstance()
      if active {
        try session.setActive(true)
        UIApplication.shared.beginReceivingRemoteControlEvents()
      } else {
        UIApplication.shared.endReceivingRemoteControlEvents()
        try session.setActive(false, options: [.notifyOthersOnDeactivation])
      }
    }
  }

  func registerObserversIfNeeded(eventHandler: @escaping (AudioSessionEvent) -> Void) {
    onMain {
      self.eventHandler = eventHandler
      let center = NotificationCenter.default

      if interruptionObserver == nil {
        interruptionObserver = center.addObserver(
          forName: AVAudioSession.interruptionNotification,
          object: AVAudioSession.sharedInstance(),
          queue: .main
        ) { [weak self] notification in
          self?.handleInterruption(notification)
        }
      }

      if routeChangeObserver == nil {
        routeChangeObserver = center.addObserver(
          forName: AVAudioSession.routeChangeNotification,
          object: AVAudioSession.sharedInstance(),
          queue: .main
        ) { [weak self] notification in
          self?.handleRouteChange(notification)
        }
      }
    }
  }

  func unregisterObservers() {
    onMain {
      let center = NotificationCenter.default

      if let interruptionObserver {
        center.removeObserver(interruptionObserver)
        self.interruptionObserver = nil
      }

      if let routeChangeObserver {
        center.removeObserver(routeChangeObserver)
        self.routeChangeObserver = nil
      }

      eventHandler = nil
    }
  }

  private func handleInterruption(_ notification: Notification) {
    guard
      let userInfo = notification.userInfo,
      let rawType = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
      let type = AVAudioSession.InterruptionType(rawValue: rawType)
    else {
      return
    }

    switch type {
    case .began:
      eventHandler?(.interruptionBegan)
    case .ended:
      let optionsRaw = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt ?? 0
      let options = AVAudioSession.InterruptionOptions(rawValue: optionsRaw)
      eventHandler?(.interruptionEnded(shouldResume: options.contains(.shouldResume)))
    @unknown default:
      break
    }
  }

  private func handleRouteChange(_ notification: Notification) {
    guard
      let userInfo = notification.userInfo,
      let rawReason = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
      let reason = AVAudioSession.RouteChangeReason(rawValue: rawReason)
    else {
      return
    }

    if reason == .oldDeviceUnavailable {
      eventHandler?(.oldDeviceUnavailable)
    } else {
      // The output route changed (e.g. switched to Bluetooth/AirPods); output latency
      // may have changed, so let the runtime re-emit state with the fresh value.
      eventHandler?(.routeChanged)
    }
  }

  private func onMain<T>(_ block: () throws -> T) rethrows -> T {
    if Thread.isMainThread {
      return try block()
    }
    return try DispatchQueue.main.sync(execute: block)
  }
}
