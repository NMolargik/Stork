//
//  WatchHaptics.swift
//  StorkWatch Watch App
//
//  Created by Nick Molargik on 1/17/26.
//

import WatchKit

/// Watch-specific haptic feedback utilities
enum WatchHaptics {

    /// Light tap for button presses and increments
    static func lightImpact() {
        WKInterfaceDevice.current().play(.click)
    }

    /// Medium tap for confirmations
    static func mediumImpact() {
        WKInterfaceDevice.current().play(.click)
    }

    /// Success feedback
    static func success() {
        WKInterfaceDevice.current().play(.success)
    }

    /// Error feedback
    static func error() {
        WKInterfaceDevice.current().play(.failure)
    }

    /// Milestone celebration - distinctive pattern
    static func milestone() {
        let device = WKInterfaceDevice.current()
        // Play a celebratory sequence
        device.play(.notification)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            device.play(.success)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            device.play(.success)
        }
    }

    /// Direction up feedback (for increments)
    static func directionUp() {
        WKInterfaceDevice.current().play(.directionUp)
    }

    /// Direction down feedback (for decrements)
    static func directionDown() {
        WKInterfaceDevice.current().play(.directionDown)
    }

    /// Start feedback (for beginning an action)
    static func start() {
        WKInterfaceDevice.current().play(.start)
    }

    /// Stop feedback (for ending an action)
    static func stop() {
        WKInterfaceDevice.current().play(.stop)
    }
}
