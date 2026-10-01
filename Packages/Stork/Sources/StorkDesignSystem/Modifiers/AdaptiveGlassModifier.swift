//
//  AdaptiveGlassModifier.swift
//  StorkDesignSystem
//
//  Applies the Liquid Glass effect on iOS and a tinted rounded-rect fallback elsewhere.
//  Use via `.adaptiveGlass(tint:)`.
//

import SwiftUI

public struct AdaptiveGlassModifier: ViewModifier {
    private let tint: Color

    public init(tint: Color) {
        self.tint = tint
    }

    public func body(content: Content) -> some View {
        #if os(iOS)
        content.glassEffect(.regular.interactive().tint(tint))
        #else
        content
            .background(tint)
            .cornerRadius(20)
        #endif
    }
}

public extension View {
    /// Applies the adaptive Liquid Glass background with the given tint.
    func adaptiveGlass(tint: Color) -> some View {
        modifier(AdaptiveGlassModifier(tint: tint))
    }
}
