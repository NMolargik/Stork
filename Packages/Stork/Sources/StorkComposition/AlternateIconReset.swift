//
//  AlternateIconReset.swift
//  StorkComposition
//
//  4.0 removed alternate app icons. Anyone who had picked one falls back to the primary
//  icon: the first launch of 4.0 clears the alternate once and forgets the old preference.
//

#if os(iOS)
import UIKit
import os
import StorkCore

@MainActor
enum AlternateIconReset {
    private static let doneKey = "didResetAlternateIcon4"
    /// The key the removed icon picker stored its choice under.
    private static let legacyChoiceKey = "selectedIconColor"

    static func runOnce(defaults: UserDefaults = .standard) {
        guard !defaults.bool(forKey: doneKey) else { return }
        defaults.set(true, forKey: doneKey)
        defaults.removeObject(forKey: legacyChoiceKey)
        guard UIApplication.shared.supportsAlternateIcons, UIApplication.shared.alternateIconName != nil else { return }
        Task {
            do {
                try await UIApplication.shared.setAlternateIconName(nil)
            } catch {
                Log.app.error("Could not restore the primary app icon: \(error.localizedDescription, privacy: .public)")
            }
        }
    }
}
#endif
