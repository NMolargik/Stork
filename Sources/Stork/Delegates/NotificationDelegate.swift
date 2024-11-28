//
//  NotificationDelegate.swift
//
//
//  Created by Nick Molargik on 11/27/24.
//

import StorkModel
import Foundation
import OSLog
import SwiftUI
#if SKIP
import SkipFirebaseMessaging
#else
import FirebaseMessaging
#endif

public class NotificationDelegate : NSObject, UNUserNotificationCenterDelegate, MessagingDelegate {
    public func requestPermission() {
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        Task { @MainActor in
            do {
                if try await UNUserNotificationCenter.current().requestAuthorization(options: authOptions) {
                    logger.info("notification permission granted")
                } else {
                    logger.info("notification permission denied")
                }
            } catch {
                logger.error("notification permission error: \(error)")
            }
        }
    }

    @MainActor
    public func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        let content = notification.request.content
        logger.info("willPresentNotification: \(content.title): \(content.body) \(content.userInfo)")
        return [.banner, .sound]
    }

    @MainActor
    public func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
        let content = response.notification.request.content
        logger.info("didReceiveNotification: \(content.title): \(content.body) \(content.userInfo)")
        #if SKIP || !os(macOS)
        // Example of using a deep_link key passed in the notification to route to the app's `onOpenURL` handler
        if let deepLink = response.notification.request.content.userInfo["deep_link"] as? String, let url = URL(string: deepLink) {
            await UIApplication.shared.open(url)
        }
        #endif
    }

    public func messaging(_ messaging: Messaging, didReceiveRegistrationToken token: String?) {
        logger.info("didReceiveRegistrationToken: \(token ?? "nil")")
    }
}
