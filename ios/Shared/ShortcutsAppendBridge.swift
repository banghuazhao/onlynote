import Foundation
import CoreFoundation
import AppIntents
#if os(iOS)
@preconcurrency import Flutter
#else
@preconcurrency import FlutterMacOS
#endif

@MainActor
enum ShortcutsAppendBridge {
    private static var channel: FlutterMethodChannel?
    private static var observing = false

    static func register(messenger: FlutterBinaryMessenger) {
        let bridge = FlutterMethodChannel(name: "com.appsbay.onlynote/shortcuts_append", binaryMessenger: messenger)
        channel = bridge
        bridge.setMethodCallHandler { call, result in
            MainActor.assumeIsolated {
                do {
                    let store = try ShortcutsAppendStore()
                    switch call.method {
                    case "pending": result(try store.pending())
                    case "acknowledge":
                        guard let id = (call.arguments as? [String: Any])?["id"] as? String else {
                            throw ShortcutsAppendStore.AppendError.invalidRequest
                        }
                        try store.acknowledge(id)
                        result(nil)
                    case "saveCatalog":
                        guard let values = call.arguments as? [[String: Any]] else {
                            throw ShortcutsAppendStore.AppendError.invalidRequest
                        }
                        try store.saveCatalog(values)
                        if #available(iOS 16.0, macOS 13.0, *) {
                            OnlynoteAppendShortcuts.updateAppShortcutParameters()
                        }
                        result(nil)
                    default: result(FlutterMethodNotImplemented)
                    }
                } catch {
                    result(FlutterError(code: "shortcuts_append", message: error.localizedDescription, details: nil))
                }
            }
        }
        if !observing {
            observing = true
            CFNotificationCenterAddObserver(
                CFNotificationCenterGetDarwinNotifyCenter(), nil,
                { _, _, _, _, _ in
                    Task { @MainActor in
                        ShortcutsAppendBridge.channel?.invokeMethod("commandsChanged", arguments: nil)
                    }
                }, ShortcutsAppendStore.notification as CFString, nil, .deliverImmediately
            )
        }
    }
}
