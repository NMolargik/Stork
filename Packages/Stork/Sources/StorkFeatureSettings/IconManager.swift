//
//  IconManager.swift
//  StorkFeatureSettings
//
//  Switches the app's alternate icon, retrying on the transient EAGAIN the system throws
//  when asked too early. Alternate icon keys come from the app's Info.plist.
//

#if os(iOS)
import SwiftUI
import os
import StorkCore

@MainActor
@Observable
public final class IconManager {
    public var isChangingIcon = false
    private var retryCount = 0
    private let maxRetries = 3

    private let primaryIconColorKey = "purple"
    private let alternateIconKeyForColor: [String: String] = [
        "blue": "IconBlue",
        "pink": "IconPink",
        "orange": "IconOrange",
    ]

    public init() {}

    public func changeAppIcon(to color: String) async {
        guard UIApplication.shared.supportsAlternateIcons else {
            Log.app.info("Alternate icons not supported.")
            isChangingIcon = false
            return
        }
        guard !isChangingIcon else { return }

        isChangingIcon = true
        retryCount = 0

        while !canPresentIconAlertNow() {
            try? await Task.sleep(nanoseconds: 100_000_000)
        }

        let targetIsPrimary = color == primaryIconColorKey
        let targetKey: String? = targetIsPrimary ? nil : alternateIconKeyForColor[color]

        if !targetIsPrimary {
            guard let key = targetKey, availableAlternateIconKeys().contains(key) else {
                Log.app.error("Icon key for \(color) unavailable")
                isChangingIcon = false
                return
            }
        }

        let current = UIApplication.shared.alternateIconName
        if (targetIsPrimary && current == nil) || (!targetIsPrimary && current == targetKey) {
            isChangingIcon = false
            return
        }

        await setIcon(to: targetKey)
    }

    private func setIcon(to name: String?) async {
        do {
            try await UIApplication.shared.setAlternateIconName(name)
            Log.app.info("Icon changed to \(name ?? "primary")")
            isChangingIcon = false
        } catch let error as NSError {
            if error.domain == NSPOSIXErrorDomain && error.code == 35 && retryCount < maxRetries {
                retryCount += 1
                let delay = 0.4 + Double(retryCount) * 0.3
                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                await setIcon(to: name)
            } else {
                Log.app.error("Failed to change icon: \(error.localizedDescription)")
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
        guard let icons = Bundle.main.infoDictionary?["CFBundleIcons"] as? [String: Any],
              let alternates = icons["CFBundleAlternateIcons"] as? [String: Any] else { return [] }
        return Set(alternates.keys)
    }
}
#endif
