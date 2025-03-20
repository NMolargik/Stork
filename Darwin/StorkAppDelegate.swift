//
//  StorkAppDelegate.swift
//  
//
//  Created by Nick Molargik on 3/14/25.
//

import UIKit
import FirebaseCore

#if SKIP || !os(macOS)
/// iOS uses the app delegate to integrate push notifications.
///
/// See Main.kt for the equivalent Android functionality.
class StorkAppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        FirebaseApp.configure()
        return true
    }
}
#endif
