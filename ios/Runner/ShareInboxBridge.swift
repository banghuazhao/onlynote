import Flutter
import Foundation

/// Read the app group's inbox without blocking Flutter's main isolate.
enum ShareInboxBridge {
    static func register(messenger: FlutterBinaryMessenger) {
        let channel = FlutterMethodChannel(
            name: "com.appsbay.onlynote/shared_notes", binaryMessenger: messenger
        )
        channel.setMethodCallHandler { call, result in
            guard call.method == "pending" || call.method == "acknowledge" else {
                result(FlutterMethodNotImplemented)
                return
            }
            let method = call.method
            let id = (call.arguments as? [String: Any])?["id"] as? String
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    let value: Any?
                    if method == "pending" {
                        value = try ShareInbox.pending()
                    } else if let id {
                        try ShareInbox.acknowledge(id)
                        value = nil
                    } else {
                        throw ShareInbox.InboxError.invalid
                    }
                    DispatchQueue.main.async { result(value) }
                } catch {
                    DispatchQueue.main.async {
                        result(FlutterError(code: "share_inbox", message: "Shared content is retained for retry.", details: nil))
                    }
                }
            }
        }
    }
}
