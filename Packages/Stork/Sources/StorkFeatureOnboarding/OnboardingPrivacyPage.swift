//
//  OnboardingPrivacyPage.swift
//  StorkFeatureOnboarding
//

#if os(iOS)
import SwiftUI
import StorkDesignSystem

struct OnboardingPrivacyPage: View {
    @State private var hasAppeared = false

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                VStack(spacing: 16) {
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 64)).foregroundStyle(.storkPurple)
                        .symbolEffect(.bounce, value: hasAppeared)
                        .accessibilityHidden(true)
                    Text("Your Privacy Matters", bundle: .module).font(.title.bold())
                    Text("Stork is designed to keep your data private and secure.", bundle: .module)
                        .font(.body).foregroundStyle(.secondary).multilineTextAlignment(.center).padding(.horizontal)
                }
                .padding(.top, 24)

                VStack(spacing: 0) {
                    PrivacyRow(icon: "iphone", iconColor: .storkBlue, title: String(localized: "On-Device Storage", bundle: .module), description: String(localized: "Your data stays on your device and in your personal iCloud.", bundle: .module))
                    Divider().padding(.leading, 56)
                    PrivacyRow(icon: "person.fill.questionmark", iconColor: .storkOrange, title: String(localized: "No Patient Data", bundle: .module), description: String(localized: "Only your personal delivery stats are tracked.", bundle: .module))
                    Divider().padding(.leading, 56)
                    PrivacyRow(icon: "building.2", iconColor: .storkPink, title: String(localized: "No Hospital Data", bundle: .module), description: String(localized: "We don't store where deliveries occur.", bundle: .module))
                    Divider().padding(.leading, 56)
                    PrivacyRow(icon: "checkmark.shield.fill", iconColor: .green, title: String(localized: "HIPAA Compliant", bundle: .module), description: String(localized: "No Protected Health Information is collected.", bundle: .module))
                }
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .frame(maxWidth: 500)
                .padding(.horizontal, 20)

                Spacer(minLength: 120)
            }
            .frame(maxWidth: .infinity)
        }
        .scrollIndicators(.hidden)
        .onAppear { hasAppeared = true }
    }
}

private struct PrivacyRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon).font(.title3).foregroundStyle(iconColor).frame(width: 28).accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.subheadline.weight(.semibold))
                Text(description).font(.subheadline).foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(.horizontal, 16).padding(.vertical, 14)
        .accessibilityElement(children: .combine)
    }
}
#endif
