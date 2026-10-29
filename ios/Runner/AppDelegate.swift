import Flutter
import UIKit
import flutter_local_notifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        if #available(iOS 10.0, *) {
            UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
        }
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
        // Notification actions use a separate engine when the app is closed.
        FlutterLocalNotificationsPlugin.setPluginRegistrantCallback { registry in
            GeneratedPluginRegistrant.register(with: registry)
        }
        GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
        if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "OnlynoteAppShortcuts") {
            AppShortcutBridge.register(messenger: registrar.messenger())
            ShareInboxBridge.register(messenger: registrar.messenger())
            ShortcutsAppendBridge.register(messenger: registrar.messenger())
            WidgetCommandBridge.register(messenger: registrar.messenger())
            PhotoTextBridge.register(messenger: registrar.messenger())
            DocumentScanBridge.register(messenger: registrar.messenger())
            VoiceMemoBridge.register(messenger: registrar.messenger())
        }
    }
}

/// Static icon actions exist before the first launch; retain a cold action
/// until Dart has finished storage recovery and attached its router.
private enum AppShortcutBridge {
    private static var channel: FlutterMethodChannel?
    private static var ready = false
    private static var pending: [String: String]?

    static func register(messenger: FlutterBinaryMessenger) {
        ready = false
        let bridge = FlutterMethodChannel(
            name: "com.appsbay.onlynote/app_shortcuts",
            binaryMessenger: messenger
        )
        channel = bridge
        bridge.setMethodCallHandler { call, result in
            guard call.method == "initialize" else {
                result(FlutterMethodNotImplemented)
                return
            }
            ready = true
            let initial = pending
            pending = nil
            result(initial)
        }
    }

    @discardableResult
    static func handle(_ shortcut: UIApplicationShortcutItem) -> Bool {
        let prefix = "com.appsbay.onlynote."
        guard shortcut.type.hasPrefix(prefix) else { return false }
        let type = String(shortcut.type.dropFirst(prefix.count))
        guard ["new_note", "new_checklist", "photo_note", "voice_note"].contains(type) else { return false }
        let request = ["id": UUID().uuidString, "type": type]
        if ready, let channel {
            channel.invokeMethod("shortcutTapped", arguments: request)
        } else {
            pending = request
        }
        return true
    }
}

/// Keep Flutter's scene lifecycle forwarding for widgets and notifications.
class OnlynoteSceneDelegate: FlutterSceneDelegate {
    override func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        super.scene(scene, willConnectTo: session, options: connectionOptions)
        if let shortcut = connectionOptions.shortcutItem {
            AppShortcutBridge.handle(shortcut)
        }
    }

    override func windowScene(
        _ windowScene: UIWindowScene,
        performActionFor shortcutItem: UIApplicationShortcutItem,
        completionHandler: @escaping (Bool) -> Void
    ) {
        if AppShortcutBridge.handle(shortcutItem) {
            completionHandler(true)
        } else {
            super.windowScene(
                windowScene,
                performActionFor: shortcutItem,
                completionHandler: completionHandler
            )
        }
    }
}
