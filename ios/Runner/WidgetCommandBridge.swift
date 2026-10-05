import Flutter
import Foundation
import CoreFoundation

/// Reads the extension's journal without opening the note database in native code.
enum WidgetCommandBridge {
    private static var eventChannel: FlutterMethodChannel?
    private static var observing = false
    static func register(messenger: FlutterBinaryMessenger) {
        let channel = FlutterMethodChannel(
            name: "com.appsbay.onlynote/widget_commands", binaryMessenger: messenger
        )
        eventChannel = channel
        if !observing {
            observing = true
            CFNotificationCenterAddObserver(
                CFNotificationCenterGetDarwinNotifyCenter(), nil,
                { _, _, _, _, _ in
                    DispatchQueue.main.async {
                        WidgetCommandBridge.eventChannel?.invokeMethod("commandsChanged", arguments: nil)
                    }
                },
                "com.appsbay.onlynote.widget_commands" as CFString, nil, .deliverImmediately
            )
        }
        channel.setMethodCallHandler { call, result in
            guard let root = FileManager.default.containerURL(
                forSecurityApplicationGroupIdentifier: "group.com.appsbay.onlynote"
            )?.appendingPathComponent("widget_commands", isDirectory: true) else {
                result(FlutterError(code: "widget_group", message: "App Group unavailable", details: nil))
                return
            }
            do {
                switch call.method {
                case "readPending":
                    let files = (try? FileManager.default.contentsOfDirectory(
                        at: root, includingPropertiesForKeys: nil
                    )) ?? []
                    let records = files.filter { $0.pathExtension == "json" }.compactMap { file -> [String: Any]? in
                        guard let data = try? Data(contentsOf: file),
                              let record = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                            return nil
                        }
                        return record
                    }
                    result(records)
                case "acknowledge":
                    for id in (call.arguments as? [String]) ?? [] where
                        !id.isEmpty && id.count <= 128 && id.allSatisfy({ $0.isASCII && ($0.isLetter || $0.isNumber || $0 == "-") }) {
                        let file = root.appendingPathComponent(id).appendingPathExtension("json")
                        if FileManager.default.fileExists(atPath: file.path) {
                            try FileManager.default.removeItem(at: file)
                        }
                    }
                    result(nil)
                default:
                    result(FlutterMethodNotImplemented)
                }
            } catch {
                result(FlutterError(code: "widget_commands", message: error.localizedDescription, details: nil))
            }
        }
    }
}
