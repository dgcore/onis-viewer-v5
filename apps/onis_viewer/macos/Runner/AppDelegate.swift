import Cocoa
import FlutterMacOS
import desktop_multi_window

@main
class AppDelegate: FlutterAppDelegate {
  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }

  override func applicationDidFinishLaunching(_ notification: Notification) {
    FlutterMultiWindowPlugin.setOnWindowCreatedCallback { controller in
      RegisterGeneratedPlugins(registry: controller)
      // desktop_multi_window defaults to a hidden/transparent title bar; restore
      // standard chrome for display sub-windows.
      AppDelegate.restoreStandardTitleBar(for: controller)
      // window_manager can break the main-window entry in MultiWindowManager;
      // re-attach so invokeMethod(target: 0) reaches the main Flutter engine.
      AppDelegate.reattachMainFlutterWindow()
    }

    super.applicationDidFinishLaunching(notification)

    DispatchQueue.main.async {
      AppDelegate.reattachMainFlutterWindow()
    }
  }

  /// Reverts [FlutterWindow] hidden-title defaults from desktop_multi_window.
  private static func restoreStandardTitleBar(for controller: FlutterViewController) {
    func apply(to window: NSWindow) {
      window.styleMask.insert([.titled, .closable, .miniaturizable, .resizable])
      window.styleMask.remove(.fullSizeContentView)
      window.titleVisibility = .visible
      window.titlebarAppearsTransparent = false
      window.isOpaque = true
      window.hasShadow = true
      if let titleBar = window.standardWindowButton(.closeButton)?
        .superview?
        .superview {
        titleBar.isHidden = false
      }
      window.standardWindowButton(.closeButton)?.isHidden = false
      window.standardWindowButton(.miniaturizeButton)?.isHidden = false
      window.standardWindowButton(.zoomButton)?.isHidden = false
    }

    if let window = controller.view.window {
      apply(to: window)
      return
    }
    DispatchQueue.main.async {
      guard let window = controller.view.window else { return }
      apply(to: window)
    }
  }

  /// Ensures [MultiWindowManager] maps window id `0` to the main isolate's channel.
  private static func reattachMainFlutterWindow() {
    guard let app = NSApplication.shared.delegate as? FlutterAppDelegate,
          let mainWindow = app.mainFlutterWindow,
          let flutterViewController = mainWindow.contentViewController as? FlutterViewController
    else {
      debugPrint("ONIS: reattachMainFlutterWindow — main FlutterViewController not found")
      return
    }
    let registrar = flutterViewController.registrar(forPlugin: "FlutterMultiWindowPlugin")
    FlutterMultiWindowPlugin.register(with: registrar)
  }
  
}
