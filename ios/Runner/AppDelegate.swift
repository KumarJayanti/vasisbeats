import UIKit
import Flutter
import FirebaseCore

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    FirebaseApp.configure()
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // ✅ Universal Links (works when scenes are not used OR even when they are, iOS calls both)
  override func application(_ application: UIApplication,
                            continue userActivity: NSUserActivity,
                            restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
    var handled = false
    if userActivity.activityType == NSUserActivityTypeBrowsingWeb,
       let url = userActivity.webpageURL {
      // Broadcast to Flutter (optional if you rely on app_links plugin)
      NotificationCenter.default.post(
        name: Notification.Name("IncomingLink"),
        object: url.absoluteString
      )
      handled = true
    }
    // Forward to FlutterAppDelegate so registered plugins (e.g., app_links) also receive the event
    let superHandled = super.application(application, continue: userActivity, restorationHandler: restorationHandler)
    return handled || superHandled
  }

  // (Optional) Custom URL scheme fallback if you ever use schemes instead of Universal Links
  override func application(_ app: UIApplication,
                            open url: URL,
                            options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
    NotificationCenter.default.post(
      name: Notification.Name("IncomingLink"),
      object: url.absoluteString
    )
    // Forward to FlutterAppDelegate for plugin handling
    let superHandled = super.application(app, open: url, options: options)
    return true || superHandled
  }
}
