import AppKit
import CoreFoundation
@preconcurrency import FlutterMacOS
import WidgetKit

/// Retains cold widget links until Dart's router and recovery are ready.
@MainActor
final class MacWidgetBridge {
    private static var retained: MacWidgetBridge?
    private static var pendingURL: String?
    private static var observingCommands = false
    private let channel: FlutterMethodChannel
    private let commands: FlutterMethodChannel
    private var ready = false

    static func register(messenger: FlutterBinaryMessenger) {
        retained = MacWidgetBridge(messenger: messenger)
        if !observingCommands {
            observingCommands = true
            CFNotificationCenterAddObserver(
                CFNotificationCenterGetDarwinNotifyCenter(), nil,
                { _, _, _, _, _ in
                    Task { @MainActor in
                        MacWidgetBridge.retained?.commands.invokeMethod("commandsChanged", arguments: nil)
                    }
                },
                MacWidgetStore.commandNotification as CFString, nil, .deliverImmediately
            )
        }
    }

    @discardableResult
    static func open(_ url: URL) -> Bool {
        guard accepts(url) else { return false }
        NSApplication.shared.activate(ignoringOtherApps: true)
        if let bridge = retained, bridge.ready {
            bridge.channel.invokeMethod("widgetTapped", arguments: url.absoluteString)
        } else {
            pendingURL = url.absoluteString
        }
        return true
    }

    static func accepts(_ url: URL) -> Bool {
        guard url.scheme == "onlynote", let host = url.host,
              ["open", "note", "new", "voice"].contains(host),
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              components.queryItems?.contains(where: { $0.name == "homeWidget" && $0.value == "true" }) == true else {
            return false
        }
        return host != "note" || components.queryItems?.contains(where: {
            $0.name == "id" && !($0.value?.isEmpty ?? true) && ($0.value?.count ?? 0) <= 256
        }) == true
    }

    private init(messenger: FlutterBinaryMessenger) {
        channel = FlutterMethodChannel(name: "com.appsbay.onlynote/mac_widgets", binaryMessenger: messenger)
        commands = FlutterMethodChannel(name: "com.appsbay.onlynote/widget_commands", binaryMessenger: messenger)
        channel.setMethodCallHandler { [weak self] call, result in
            MainActor.assumeIsolated {
                guard let self else { result(FlutterMethodNotImplemented); return }
                self.handle(call, result: result)
            }
        }
        commands.setMethodCallHandler { call, result in
            MainActor.assumeIsolated {
                do {
                    let store = try MacWidgetStore()
                    switch call.method {
                    case "readPending": result(try store.readPending())
                    case "acknowledge":
                        try store.acknowledge(call.arguments as? [String] ?? [])
                        result(nil)
                    default: result(FlutterMethodNotImplemented)
                    }
                } catch {
                    result(FlutterError(code: "widget_group", message: error.localizedDescription, details: nil))
                }
            }
        }
    }

    private func handle(_ call: FlutterMethodCall, result: FlutterResult) {
        do {
            switch call.method {
            case "initialize":
                ready = true
                let initial = Self.pendingURL
                Self.pendingURL = nil
                result(initial)
            case "saveSnapshot":
                guard let arguments = call.arguments as? [String: Any],
                      let payload = arguments["payload"] as? String else {
                    result(FlutterError(code: "widget_payload", message: "Invalid widget snapshot", details: nil))
                    return
                }
                try MacWidgetStore().saveSnapshot(payload)
                result(nil)
            case "refresh":
                WidgetCenter.shared.reloadAllTimelines()
                result(nil)
            default: result(FlutterMethodNotImplemented)
            }
        } catch {
            result(FlutterError(code: "widget_group", message: error.localizedDescription, details: nil))
        }
    }
}
