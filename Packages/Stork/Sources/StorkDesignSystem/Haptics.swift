//
//  Haptics.swift
//  StorkDesignSystem
//
//  Thin wrapper over UIKit feedback generators, no-ops off iOS and when disabled.
//

#if canImport(UIKit)
import UIKit
#endif

public enum Haptics {
    /// When false, every trigger is a no-op (honored app-wide from a setting).
    public static var isEnabled: Bool = true

    public static func lightImpact() {
        #if os(iOS)
        impact(.light)
        #endif
    }

    public static func mediumImpact() {
        #if os(iOS)
        impact(.medium)
        #endif
    }

    public static func heavyImpact() {
        #if os(iOS)
        impact(.heavy)
        #endif
    }

    public static func success() {
        #if os(iOS)
        notify(.success)
        #endif
    }

    public static func error() {
        #if os(iOS)
        notify(.error)
        #endif
    }

    #if os(iOS)
    private static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        guard isEnabled else { return }
        let gen = UIImpactFeedbackGenerator(style: style)
        gen.prepare()
        gen.impactOccurred()
    }

    private static func notify(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        guard isEnabled else { return }
        let gen = UINotificationFeedbackGenerator()
        gen.prepare()
        gen.notificationOccurred(type)
    }
    #endif
}
