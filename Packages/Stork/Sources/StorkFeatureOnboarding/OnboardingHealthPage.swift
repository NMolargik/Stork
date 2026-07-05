//
//  OnboardingHealthPage.swift
//  StorkFeatureOnboarding
//

#if os(iOS)
import SwiftUI
import UIKit
import StorkDesignSystem
import StorkServices

struct OnboardingHealthPage: View {
    @Environment(HealthManager.self) private var healthManager

    private var statusConfig: (icon: String, color: Color, title: String, description: String) {
        if healthManager.isAuthorized {
            ("checkmark.circle.fill", .green, "Health Connected", "We'll show your daily step count on the dashboard.")
        } else if healthManager.lastError != nil {
            ("heart.slash.fill", .orange, "Access Denied", "Enable Health access in Settings to see your steps.")
        } else {
            ("heart.fill", .pink, "Connect Health", "Allow access to show your daily step count.")
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                VStack(spacing: 16) {
                    Image(systemName: statusConfig.icon)
                        .font(.system(size: 64)).foregroundStyle(statusConfig.color)
                        .contentTransition(.symbolEffect(.replace)).accessibilityHidden(true)
                    Text(statusConfig.title).font(.title.bold())
                    Text(statusConfig.description).font(.body).foregroundStyle(.secondary).multilineTextAlignment(.center).padding(.horizontal)
                }
                .padding(.top, 24)

                VStack(spacing: 0) {
                    OnboardingFeatureRow(icon: "figure.walk", iconColor: .green, title: "Step Counter", description: "Track your daily steps during shifts.")
                }
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .frame(maxWidth: 500)
                .padding(.horizontal, 20)

                if healthManager.isAuthorized {
                    VStack(spacing: 8) {
                        Text("Today's Steps").font(.subheadline).foregroundStyle(.secondary)
                        Text("\(healthManager.todayStepCount)").font(.system(size: 48, weight: .bold, design: .rounded))
                    }
                    .padding().frame(maxWidth: 500)
                    .background(Color(uiColor: .secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal, 20)
                }

                if !healthManager.isAuthorized && healthManager.lastError != nil {
                    Button {
                        if let url = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(url) }
                    } label: {
                        Label("Open Settings", systemImage: "gear")
                            .font(.headline).frame(maxWidth: .infinity).frame(height: 50)
                            .background(Color.secondary.opacity(0.2)).foregroundStyle(.primary)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .buttonStyle(.plain)
                    .frame(maxWidth: 500)
                    .padding(.horizontal, 20)
                }

                Spacer(minLength: 120)
            }
            .frame(maxWidth: .infinity)
        }
        .scrollIndicators(.hidden)
    }
}
#endif
