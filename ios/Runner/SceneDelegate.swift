import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
  var window: UIWindow?

  func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
    guard userActivity.activityType == NSUserActivityTypeBrowsingWeb,
          let url = userActivity.webpageURL else { return }

    // Forward to Flutter via NotificationCenter or a MethodChannel
    NotificationCenter.default.post(name: Notification.Name("IncomingLink"), object: url.absoluteString)
  }
}
