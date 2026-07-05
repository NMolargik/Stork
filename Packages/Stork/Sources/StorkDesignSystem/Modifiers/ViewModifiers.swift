//
//  ViewModifiers.swift
//  StorkDesignSystem
//
//  Shared SwiftUI view modifiers: shimmer, stat-pill background, OS-gated toolbar/tab
//  accessories, and a conditional `if` helper. (`adaptiveGlass` lives in
//  AdaptiveGlassModifier.swift.)
//

import SwiftUI

public extension View {
    /// A sweeping highlight, used on loading/placeholder content.
    func shimmer() -> some View {
        modifier(ShimmerModifier())
    }

    /// Glassy rounded background used by stat pills.
    func statPillBackground() -> some View {
        modifier(StatPillBackground())
    }

    /// Bottom accessory exists on iOS only; no-op elsewhere (visionOS).
    @ContentBuilder
    func tabViewBottomAccessoryIfAvailable<Accessory: View>(@ContentBuilder _ accessory: () -> Accessory) -> some View {
        #if os(iOS)
        tabViewBottomAccessory(content: accessory)
        #else
        self
        #endif
    }

    /// Minimizes the toolbar on scroll where the OS supports it (iOS 27+).
    @ContentBuilder
    func minimizeToolbarOnScrollIfAvailable() -> some View {
        #if os(iOS)
        if #available(iOS 27.0, *) {
            toolbarMinimizeBehavior(.onScrollDown)
        } else {
            self
        }
        #else
        self
        #endif
    }

    /// Applies `transform` only when `condition` is true.
    @ContentBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition { transform(self) } else { self }
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
                LinearGradient(
                    gradient: Gradient(colors: [.clear, .white.opacity(0.35), .clear]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
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
