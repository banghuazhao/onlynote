import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  private var exitRequestPending = false

  override func awakeFromNib() {
    // AppKit loads the main nib on the main thread, although NSObject's
    // awakeFromNib declaration predates actor isolation.
    MainActor.assumeIsolated { configureFlutterWindow() }
    super.awakeFromNib()
  }

  @MainActor
  private func configureFlutterWindow() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)
    PhotoTextBridge.register(messenger: flutterViewController.engine.binaryMessenger)
    VoiceMemoBridge.register(messenger: flutterViewController.engine.binaryMessenger)

    title = "Onlynote"
    minSize = NSSize(width: 560, height: 440)
    setContentSize(NSSize(width: 1100, height: 760))
    setFrame(constrainFrameRect(frame, to: screen), display: true)
    center()
  }

  // Closing the sole window should use Flutter's cancelable app-exit flow,
  // so an editor can finish its save before the engine is torn down.
  override func performClose(_ sender: Any?) {
    guard !exitRequestPending,
          let controller = contentViewController as? FlutterViewController else { return }
    exitRequestPending = true
    let channel = FlutterMethodChannel(
      name: "flutter/platform", binaryMessenger: controller.engine.binaryMessenger,
      codec: FlutterJSONMethodCodec.sharedInstance()
    )
    channel.invokeMethod("System.requestAppExit", arguments: ["type": "cancelable"]) { [weak self] response in
      MainActor.assumeIsolated {
        self?.exitRequestPending = false
        guard let reply = response as? [String: Any], reply["response"] as? String == "exit" else { return }
        // The application delegate forwards termination to Flutter too. All
        // save handlers are idempotent and already flushed at this point.
        NSApplication.shared.terminate(sender)
      }
    }
  }
}
