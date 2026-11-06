//
//  GrandfatherThankYouView.swift
//  StorkFeaturePro
//
//  Shown once to users who bought Stork before it went free: Pro is theirs for life.
//

#if os(iOS)
import SwiftUI
import StorkCore
import StorkDesignSystem

public struct GrandfatherThankYouView: View {
    private let onDismiss: () -> Void

    public init(onDismiss: @escaping () -> Void) {
        self.onDismiss = onDismiss
    }

    public var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "heart.fill")
                .font(.system(size: 56))
                .foregroundStyle(LinearGradient(colors: [.storkPink, .storkPurple], startPoint: .topLeading, endPoint: .bottomTrailing))
                .accessibilityHidden(true)
            Text("Thank you for supporting Stork", bundle: .module)
                .font(.title2.bold())
                .multilineTextAlignment(.center)
            Text("Stork is now free with an optional Stork Pro upgrade. Because you bought Stork before the change, every Pro feature is unlocked for you — forever, on every device signed in to your Apple Account.", bundle: .module)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button {
                Haptics.mediumImpact()
                onDismiss()
            } label: {
                Text("Continue", bundle: .module).font(.headline).frame(maxWidth: .infinity).frame(height: 38)
            }
            .buttonStyle(.glassProminent)
            .controlSize(.large)
            .tint(.storkPurple)
        }
        .padding(28)
        .frame(maxWidth: 480)
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
        .interactiveDismissDisabled()
    }
}
#endif
