import Cocoa
import FlutterMacOS
import FirebaseCore

@main
class AppDelegate: FlutterAppDelegate {

  // Keep a channel to talk to Dart
  private var linkChannel: FlutterMethodChannel?

  override func applicationDidFinishLaunching(_ notification: Notification) {
    FirebaseApp.configure()

    // Wire a MethodChannel to the root FlutterViewController
    if let controller = NSApplication.shared.windows.first?.contentViewController as? FlutterViewController {
      linkChannel = FlutterMethodChannel(
        name: "app.links/incoming",
        binaryMessenger: controller.engine.binaryMessenger
      )
    }

    super.applicationDidFinishLaunching(notification)
  }

  // Universal Links (the important one for https://auth.spiritlightsoft.com/...)
  override func application(_ application: NSApplication,
                            continue userActivity: NSUserActivity,
                            restorationHandler: @escaping ([NSUserActivityRestoring]) -> Void) -> Bool {
    var handled = false
    if userActivity.activityType == NSUserActivityTypeBrowsingWeb,
       let url = userActivity.webpageURL {
      // Send to our optional channel (not required if using app_links plugin)
      linkChannel?.invokeMethod("link", arguments: url.absoluteString)
      handled = true
    }
    // Forward to FlutterAppDelegate so registered plugins (e.g., app_links) also receive the event
    let superHandled = super.application(application, continue: userActivity, restorationHandler: restorationHandler)
    return handled || superHandled
  }

  // Fallback: if the app is asked to open URLs directly (rare for Universal Links, useful for custom schemes)
  override func application(_ app: NSApplication, open urls: [URL]) {
    if let url = urls.first {
      linkChannel?.invokeMethod("link", arguments: url.absoluteString)
    }
    // Also forward to FlutterAppDelegate for plugin handling
    super.application(app, open: urls)
  }

  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }
  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool { true }
}

