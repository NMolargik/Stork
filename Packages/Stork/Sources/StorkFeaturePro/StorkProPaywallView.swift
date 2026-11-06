//
//  StorkProPaywallView.swift
//  StorkFeaturePro
//
//  The single-product Stork Pro sheet: what you get, the price, Buy, Restore, and the
//  legal links. Opened in context from a gated feature, which is highlighted at the top
//  of the list. Takes the `StoreManager` directly (already an @Observable, presentation-
//  ready object); the outcome flows out via closures.
//

#if os(iOS)
import SwiftUI
import StorkCore
import StorkDesignSystem
import StorkServices

public struct StorkProPaywallView: View {
    private let store: StoreManager
    private let highlighted: ProFeature?
    private let onUnlocked: () -> Void

    @Environment(\.dismiss) private var dismiss

    public static let privacyPolicyURL = URL(string: "https://molargiksoftware.com/privacy")!
    public static let termsOfUseURL = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!

    /// - Parameters:
    ///   - store: The app's `StoreManager`.
    ///   - highlighted: The feature the user tapped, listed first.
    ///   - onUnlocked: Called after a successful purchase or restore (the sheet dismisses itself).
    public init(store: StoreManager, highlighted: ProFeature? = nil, onUnlocked: @escaping () -> Void = {}) {
        self.store = store
        self.highlighted = highlighted
        self.onUnlocked = onUnlocked
    }

    private var orderedFeatures: [ProFeature] {
        guard let highlighted else { return ProFeature.allCases }
        return [highlighted] + ProFeature.allCases.filter { $0 != highlighted }
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    header
                    featureList
                    purchaseBlock
                    legal
                }
                .frame(maxWidth: 560)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle(Text("Stork Pro", bundle: .module))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: { Image(systemName: "xmark") }
                        .accessibilityLabel(Text("Close", bundle: .module))
                        .keyboardShortcut(.escape, modifiers: [])
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Sections

    private var header: some View {
        VStack(spacing: 12) {
            Image(systemName: "sparkles")
                .font(.system(size: 56))
                .foregroundStyle(LinearGradient(colors: [.storkBlue, .storkPurple], startPoint: .topLeading, endPoint: .bottomTrailing))
                .accessibilityHidden(true)
            Text("Go further with Stork Pro", bundle: .module)
                .font(.title.bold())
                .multilineTextAlignment(.center)
            Text("Logging deliveries, your stats, the jar, the calendar, Siri, and the Watch app stay free forever. Pro adds the extras.", bundle: .module)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 16)
    }

    private var featureList: some View {
        VStack(spacing: 0) {
            ForEach(Array(orderedFeatures.enumerated()), id: \.element) { index, feature in
                HStack(spacing: 14) {
                    Image(systemName: feature.systemImage)
                        .font(.title3)
                        .foregroundStyle(feature == highlighted ? .storkPurple : .storkBlue)
                        .frame(width: 28)
                        .accessibilityHidden(true)
                    Text(feature.displayName)
                        .font(.body.weight(feature == highlighted ? .semibold : .regular))
                    Spacer()
                    Image(systemName: "checkmark")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.green)
                        .accessibilityHidden(true)
                }
                .padding(.horizontal, 16).padding(.vertical, 12)
                .accessibilityElement(children: .combine)
                if index < orderedFeatures.count - 1 { Divider().padding(.leading, 58) }
            }
        }
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var purchaseBlock: some View {
        VStack(spacing: 12) {
            if store.isProUnlocked {
                Label(String(localized: "Stork Pro is unlocked. Thank you!", bundle: .module), systemImage: "checkmark.seal.fill")
                    .font(.headline)
                    .foregroundStyle(.green)
                    .padding(.vertical, 8)
            } else {
                if let price = store.product?.displayPrice {
                    Text("\(price) — one time. No subscription.", bundle: .module)
                        .font(.headline)
                        .multilineTextAlignment(.center)
                } else if store.isLoading {
                    Text("Loading price…", bundle: .module).font(.headline).foregroundStyle(.secondary)
                }

                Button {
                    Haptics.mediumImpact()
                    Task {
                        if await store.purchase() { finishUnlocked() }
                    }
                } label: {
                    HStack(spacing: 8) {
                        if store.isLoading { ProgressView().tint(.white) }
                        Text("Unlock Stork Pro", bundle: .module).font(.headline)
                    }
                    .frame(maxWidth: .infinity).frame(height: 38)
                }
                .buttonStyle(.glassProminent)
                .controlSize(.large)
                .tint(.storkPurple)
                .disabled(store.isLoading || store.product == nil)
                .accessibilityIdentifier("paywall.purchase")

                Button {
                    Task {
                        if await store.restore() { finishUnlocked() }
                    }
                } label: {
                    Text("Restore Purchases", bundle: .module).font(.subheadline.weight(.medium))
                }
                .buttonStyle(.bordered)
                .disabled(store.isLoading)
            }

            if let message = store.errorMessage {
                Text(message)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
            }

            Text("Family Sharing included. Bought Stork before it went free? Pro is already yours — tap Restore Purchases if it isn't showing.", bundle: .module)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private var legal: some View {
        HStack(spacing: 16) {
            Link(destination: Self.privacyPolicyURL) { Text("Privacy Policy", bundle: .module) }
            Text(verbatim: "·").foregroundStyle(.tertiary)
            Link(destination: Self.termsOfUseURL) { Text("Terms of Use", bundle: .module) }
        }
        .font(.footnote)
        .foregroundStyle(.storkBlue)
    }

    private func finishUnlocked() {
        Haptics.heavyImpact()
        onUnlocked()
        dismiss()
    }
}
#endif
