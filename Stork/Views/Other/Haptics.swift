//
//  Haptics.swift
//  Stork
//
//  Created by Nick Molargik on 9/16/25.
//

#if canImport(UIKit)
import UIKit
#endif

enum Haptics {
    static var isEnabled: Bool = true

    static func lightImpact() {
        #if os(iOS)
        guard isEnabled else { return }
        let gen = UIImpactFeedbackGenerator(style: .light)
        gen.prepare()
        gen.impactOccurred()
        #endif
    }

    static func mediumImpact() {
        #if os(iOS)
        guard isEnabled else { return }
        let gen = UIImpactFeedbackGenerator(style: .medium)
        gen.prepare()
        gen.impactOccurred()
        #endif
    }

    static func heavyImpact() {
        #if os(iOS)
        guard isEnabled else { return }
        let gen = UIImpactFeedbackGenerator(style: .heavy)
        gen.prepare()
        gen.impactOccurred()
        #endif
    }

    static func success() {
        #if os(iOS)
        guard isEnabled else { return }
        let gen = UINotificationFeedbackGenerator()
        gen.prepare()
        gen.notificationOccurred(.success)
        #endif
    }

    static func error() {
        #if os(iOS)
        guard isEnabled else { return }
        let gen = UINotificationFeedbackGenerator()
        gen.prepare()
        gen.notificationOccurred(.error)
        #endif
    }
}
