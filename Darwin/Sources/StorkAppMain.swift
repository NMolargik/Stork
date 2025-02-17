import SwiftUI
import Stork
import FirebaseCore

/// The entry point to the app simply loads the App implementation from SPM module.
@main struct AppMain: App, StorkApp {
    #if SKIP || !os(macOS)
    @UIApplicationDelegateAdaptor(StorkAppDelegate.self) var appDelegate
    #endif
}

#if SKIP || !os(macOS)
/// iOS uses the app delegate to integrate push notifications.
///
/// See Main.kt for the equivalent Android functionality.
class StorkAppDelegate : NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        FirebaseApp.configure()
        return true
    }
}
#endif
