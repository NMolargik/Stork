//
//  View-modifiers.swift
//  Stork
//
//  Created by Nick Molargik on 9/14/25.
//

import SwiftUI

extension View {
    func shimmer() -> some View {
        self.modifier(ShimmerModifier())
    }
    
    /// Applies a glass effect with the provided tint on iOS 26+,
    /// and falls back to a simple tinted background on earlier iOS versions.
    func adaptiveGlass(tint: Color) -> some View {
        self.modifier(AdaptiveGlassModifier(tint: tint))
    }
}

public extension View {
    /// Bottom accessory exists on iOS only; no-op elsewhere (visionOS).
    @ContentBuilder
    func tabViewBottomAccessoryIfAvailable<Accessory: View>(@ContentBuilder _ accessory: () -> Accessory) -> some View {
        #if os(iOS)
        self.tabViewBottomAccessory(content: accessory)
        #else
        self
        #endif
    }

    /// Minimizes the toolbar on scroll where the OS supports it (iOS 27+).
    @ContentBuilder
    func minimizeToolbarOnScrollIfAvailable() -> some View {
        #if os(iOS)
        if #available(iOS 27.0, *) {
            self.toolbarMinimizeBehavior(.onScrollDown)
        } else {
            self
        }
        #else
        self
        #endif
    }
}

struct StatPillBackground: ViewModifier {
    func body(content: Content) -> some View {
        #if os(iOS)
        content
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .shadow(radius: 5)
        #else
        content
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .shadow(radius: 5)
            )
        #endif
    }
}

struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = -1
    
    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(gradient: Gradient(colors: [Color.clear, Color.white.opacity(0.35), Color.clear]),
                               startPoint: .topLeading,
                               endPoint: .bottomTrailing)
                    .blendMode(.plusLighter)
                    .mask(content)
                    .offset(x: phase * 180)
            )
            .onAppear {
                withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: false)) {
                    phase = 1.2
                }
            }
    }
}

extension View {
    @ContentBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition { transform(self) } else { self }
    }
}
