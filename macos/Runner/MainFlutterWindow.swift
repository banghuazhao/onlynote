import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
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
    MacWidgetBridge.register(messenger: flutterViewController.engine.binaryMessenger)

    title = "Onlynote"
    minSize = NSSize(width: 560, height: 440)
    setContentSize(NSSize(width: 1100, height: 760))
    setFrame(constrainFrameRect(frame, to: screen), display: true)
    center()
  }

  // Onlynote has one window, so its close button and ⌘W quit the app, which
  // is what macOS expects of a single-window app: there is no supported way to
  // reopen a main window once it is gone, and an app left running without one
  // looks hung.
  //
  // Quitting goes through AppKit's own termination flow so that Flutter can
  // flush pending editor saves and cancel the quit. Asking Dart here instead,
  // and terminating from inside that reply, made the engine send a second
  // System.requestAppExit whose answer never arrived through AppKit's nested
  // termination run loop, which left the app unresponsive.
  //
  // The window is never closed on its own: a cancelled quit has to leave the
  // app usable, with its window still on screen.
  override func performClose(_ sender: Any?) {
    NSApplication.shared.terminate(sender)
  }
}
