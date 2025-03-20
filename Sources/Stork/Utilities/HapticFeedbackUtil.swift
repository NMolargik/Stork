//
//  HapticFeedbackUtil.swift
//  Stork
//
//  Created by Nick Molargik on 3/14/24.
//

import UIKit

public enum HapticFeedback {
    /// Triggers a haptic feedback event.
    public static func trigger(style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        #if !SKIP
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
        #endif
    }
}
