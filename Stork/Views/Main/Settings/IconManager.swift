//
//  IconManager.swift
//  Stork
//
//  Created by Nick Molargik on 11/4/25.
//

import Foundation
import SwiftUI

@MainActor
@Observable
final class IconManager {
    var isChangingIcon = false
    private var retryCount = 0
    private let maxRetries = 3

    private let primaryIconColorKey = "purple"
    private let alternateIconKeyForColor: [String: String] = [
        "blue": "IconBlue",
        "pink": "IconPink",
        "orange": "IconOrange"
    ]

    @MainActor
    func changeAppIcon(to color: String) async {
        guard UIApplication.shared.supportsAlternateIcons else {
            print("Alternate icons not supported.")
            isChangingIcon = false
            return
        }

        guard !isChangingIcon else {
            print("Icon change already in progress.")
            return
        }

        isChangingIcon = true
        retryCount = 0

        // Wait until app is active and no modal is presented
        while !canPresentIconAlertNow() {
            print("Waiting for app to be active and no modal...")
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1s
        }

        let availableKeys = availableAlternateIconKeys()
        print("Available icon keys:", availableKeys)

        let targetIsPrimary = color == primaryIconColorKey
        let targetKey: String? = targetIsPrimary ? nil : alternateIconKeyForColor[color]

        // Validate non-primary key
        if !targetIsPrimary {
            guard let key = targetKey else {
                print("No icon key mapped for color: \(color)")
                isChangingIcon = false
                return
            }
            guard availableKeys.contains(key) else {
                print("Icon key '\(key)' not found in Info.plist")
                isChangingIcon = false
                return
            }
        }

        // Skip if already using the target icon
        let current = UIApplication.shared.alternateIconName
        if (targetIsPrimary && current == nil) || (!targetIsPrimary && current == targetKey) {
            print("Already using icon: \(targetKey ?? "primary")")
            isChangingIcon = false
            return
        }

        await setIcon(to: targetKey)
    }

    private func setIcon(to name: String?) async {
        do {
            try await UIApplication.shared.setAlternateIconName(name)
            print("Success: Icon changed to \(name ?? "primary")")
            isChangingIcon = false
        } catch let error as NSError {
            if error.domain == NSPOSIXErrorDomain && error.code == 35 && retryCount < maxRetries {
                retryCount += 1
                let delay = 0.4 + Double(retryCount) * 0.3
                print("EAGAIN – retry \(retryCount)/\(maxRetries) in \(delay)s...")
                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                await setIcon(to: name)
            } else {
                print("Failed to change icon: \(error.localizedDescription)")
                isChangingIcon = false
            }
        }
    }

    private func canPresentIconAlertNow() -> Bool {
        guard UIApplication.shared.applicationState == .active else { return false }
        guard let window = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first?.windows.first(where: { $0.isKeyWindow }) else { return false }
        return window.rootViewController?.presentedViewController == nil
    }

    private func availableAlternateIconKeys() -> Set<String> {
        guard
            let icons = Bundle.main.infoDictionary?["CFBundleIcons"] as? [String: Any],
            let alternates = icons["CFBundleAlternateIcons"] as? [String: Any]
        else { return [] }
        return Set(alternates.keys)
    }
}
