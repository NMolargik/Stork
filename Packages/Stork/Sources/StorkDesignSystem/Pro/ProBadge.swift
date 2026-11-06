//
//  ProBadge.swift
//  StorkDesignSystem
//
//  Small "PRO" capsule and a lock overlay for gated controls. Shared chrome so every
//  feature module marks locked features the same way.
//

import SwiftUI
import StorkCore

/// A compact "PRO" capsule in the brand gradient.
public struct ProBadge: View {
    public init() {}

    public var body: some View {
        Text("PRO", bundle: .module)
            .font(.caption2.weight(.heavy))
            .tracking(0.5)
            .foregroundStyle(.white)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(LinearGradient(colors: [.storkBlue, .storkPurple], startPoint: .leading, endPoint: .trailing), in: Capsule())
            .accessibilityLabel(Text("Stork Pro", bundle: .module))
    }
}

/// A lock glyph that reads as "unlock with Stork Pro".
public struct ProLockIcon: View {
    public init() {}

    public var body: some View {
        Image(systemName: "lock.fill")
            .font(.footnote.weight(.semibold))
            .foregroundStyle(.secondary)
            .accessibilityLabel(Text("Locked. Unlock with Stork Pro.", bundle: .module))
    }
}

/// A full-width row used in Settings/Export lists to advertise the Pro unlock.
public struct ProUpsellRow: View {
    private let feature: ProFeature?
    @Environment(\.requestProUpgrade) private var requestProUpgrade

    public init(feature: ProFeature? = nil) {
        self.feature = feature
    }

    public var body: some View {
        Button {
            Haptics.lightImpact()
            requestProUpgrade(feature ?? .insightCards)
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "sparkles")
                    .font(.title2)
                    .foregroundStyle(LinearGradient(colors: [.storkBlue, .storkPurple], startPoint: .top, endPoint: .bottom))
                    .frame(width: 40)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Unlock Stork Pro", bundle: .module).font(.headline)
                    Text("One-time purchase. Share cards, exports, insights, and more.", bundle: .module)
                        .font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundStyle(.tertiary).accessibilityHidden(true)
            }
        }
        .buttonStyle(.plain)
        #if os(iOS)
        .hoverEffect(.highlight)
        #endif
    }
}

public extension View {
    /// Dims the content and intercepts taps with the paywall while `locked` is true.
    /// Use on controls whose own action must not run for free users.
    @ContentBuilder
    func proLocked(_ locked: Bool, feature: ProFeature) -> some View {
        if locked {
            modifier(ProLockedModifier(feature: feature))
        } else {
            self
        }
    }
}

private struct ProLockedModifier: ViewModifier {
    let feature: ProFeature
    @Environment(\.requestProUpgrade) private var requestProUpgrade

    func body(content: Content) -> some View {
        content
            .opacity(0.55)
            .allowsHitTesting(false)
            .overlay(alignment: .topTrailing) {
                ProBadge().padding(6).accessibilityHidden(true)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                Haptics.lightImpact()
                requestProUpgrade(feature)
            }
            .accessibilityAddTraits(.isButton)
            .accessibilityHint(Text("Locked. Unlock with Stork Pro.", bundle: .module))
    }
}
