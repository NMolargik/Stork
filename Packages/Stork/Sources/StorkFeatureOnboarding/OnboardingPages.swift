//
//  OnboardingPages.swift
//  StorkFeatureOnboarding
//
//  The page bodies: one feature page per `OnboardingStep` (privacy, step count, all set).
//  Each sits at the readable width; a page tightens its spacing on short windows (the folded
//  iPhone Duo) and scrolls only when even that cannot fit. The Step Count page reflects the
//  live Health authorization state.
//

#if os(iOS)
import SwiftUI
import UIKit
import StorkCore
import StorkDesignSystem
import StorkServices

/// What a page shows in its header.
struct OnboardingPresentation {
    let icon: String
    let tint: Color
    let title: String
    let subtitle: String
}

struct OnboardingFeaturePage: View {
    let step: OnboardingStep
    let probe: LayoutProbe

    @Environment(HealthManager.self) private var healthManager

    var body: some View {
        // The roomiest layout that fits without clipping, then a tighter one, and only as a
        // last resort the tight layout scrolling. The folded Duo (466 x 678) fits the tight one.
        ViewThatFits(in: .vertical) {
            content(compact: false)
            content(compact: true)
            ScrollView {
                content(compact: true, scrolling: true)
                    .padding(.bottom, OnboardingMetrics.xl)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }

    private func content(compact: Bool, scrolling: Bool = false) -> some View {
        let presentation = presentation
        return OnboardingColumns(probe: probe, topAligned: scrolling) {
            OnboardingHeader(
                systemImage: presentation.icon,
                tint: presentation.tint,
                title: presentation.title,
                subtitle: presentation.subtitle,
                compact: compact,
                showsSymbol: !(scrolling && probe.height > 0 && probe.height < 560)
            )
        } trail: {
            VStack(spacing: OnboardingMetrics.lg) {
                rows(compact: compact)
                extras
            }
        }
        .padding(.horizontal, compact ? OnboardingMetrics.lg : OnboardingMetrics.xl)
        .padding(.vertical, compact ? OnboardingMetrics.sm : OnboardingMetrics.xl)
        // Clear of the progress dots that float over the leading column when the page scrolls.
        .padding(.top, scrolling && probe.hasFold ? 40 : 0)
        .frame(maxWidth: probe.hasFold ? .infinity : OnboardingMetrics.readableWidth)
        .frame(maxWidth: .infinity)
    }

    // MARK: Header

    private var presentation: OnboardingPresentation {
        switch step {
        case .privacy:
            return OnboardingPresentation(
                icon: "lock.shield.fill", tint: .storkPurple,
                title: String(localized: "Your Privacy Matters", bundle: .module),
                subtitle: String(localized: "Stork is designed to keep your data private and secure.", bundle: .module))
        case .health:
            if healthManager.isAuthorized {
                return OnboardingPresentation(
                    icon: "checkmark.circle.fill", tint: .green,
                    title: String(localized: "Health Connected", bundle: .module),
                    subtitle: String(localized: "We'll show your daily step count on the dashboard.", bundle: .module))
            } else if healthManager.lastError != nil {
                return OnboardingPresentation(
                    icon: "heart.slash.fill", tint: .orange,
                    title: String(localized: "Access Denied", bundle: .module),
                    subtitle: String(localized: "Enable Health access in Settings to see your steps.", bundle: .module))
            }
            return OnboardingPresentation(
                icon: "heart.fill", tint: .pink,
                title: String(localized: "Connect Health", bundle: .module),
                subtitle: String(localized: "Allow access to show your daily step count.", bundle: .module))
        case .complete:
            return OnboardingPresentation(
                icon: "checkmark.circle.fill", tint: .green,
                title: String(localized: "You're All Set!", bundle: .module),
                subtitle: String(localized: "Here's what you can do with Stork", bundle: .module))
        }
    }

    // MARK: Rows

    @ViewBuilder
    private func rows(compact: Bool) -> some View {
        switch step {
        case .privacy:
            OnboardingFeatureCard {
                OnboardingFeatureRow(icon: "iphone", tint: .storkBlue, title: String(localized: "On-Device Storage", bundle: .module), detail: String(localized: "Your data stays on your device and in your personal iCloud.", bundle: .module), compact: compact)
                OnboardingRowDivider()
                OnboardingFeatureRow(icon: "person.fill.questionmark", tint: .storkOrange, title: String(localized: "No Patient Data", bundle: .module), detail: String(localized: "Only your personal delivery stats are tracked.", bundle: .module), compact: compact)
                OnboardingRowDivider()
                OnboardingFeatureRow(icon: "building.2", tint: .storkPink, title: String(localized: "No Hospital Data", bundle: .module), detail: String(localized: "We don't store where deliveries occur.", bundle: .module), compact: compact)
                OnboardingRowDivider()
                OnboardingFeatureRow(icon: "location.slash", tint: .storkPurple, title: String(localized: "No Tracking", bundle: .module), detail: String(localized: "Location is used only if you choose to add a weather snapshot while logging, and is never stored.", bundle: .module), compact: compact)
                OnboardingRowDivider()
                OnboardingFeatureRow(icon: "checkmark.shield.fill", tint: .green, title: String(localized: "HIPAA-Conscious", bundle: .module), detail: String(localized: "Designed so you never enter protected health information.", bundle: .module), compact: compact)
            }
        case .health:
            OnboardingFeatureCard {
                OnboardingFeatureRow(icon: "figure.walk", tint: .green, title: String(localized: "Step Counter", bundle: .module), detail: String(localized: "Track your daily steps during shifts.", bundle: .module), compact: compact)
            }
        case .complete:
            OnboardingFeatureCard {
                OnboardingFeatureRow(icon: "stethoscope", tint: .storkPink, title: String(localized: "Track your deliveries", bundle: .module), compact: compact)
                OnboardingRowDivider()
                OnboardingFeatureRow(icon: "icloud.fill", tint: .storkBlue, title: String(localized: "Sync across devices", bundle: .module), compact: compact)
                OnboardingRowDivider()
                OnboardingFeatureRow(icon: "chart.line.uptrend.xyaxis", tint: .storkPurple, title: String(localized: "View trends over time", bundle: .module), compact: compact)
                OnboardingRowDivider()
                OnboardingFeatureRow(icon: "square.grid.3x3.fill", tint: .storkOrange, title: String(localized: "Fill your Delivery Jar", bundle: .module), compact: compact)
            }
        }
    }

    /// Step-count readout and the Open Settings shortcut on the Step Count page.
    @ViewBuilder
    private var extras: some View {
        if step == .health {
            if healthManager.isAuthorized {
                VStack(spacing: OnboardingMetrics.xs) {
                    Text("Today's Steps", bundle: .module).font(.subheadline).foregroundStyle(.secondary)
                    Text("\(healthManager.todayStepCount)", bundle: .module).font(.system(size: 40, weight: .bold, design: .rounded))
                }
                .padding(OnboardingMetrics.md)
                .frame(maxWidth: .infinity)
                .onboardingCard()
                .accessibilityElement(children: .combine)
            } else if healthManager.lastError != nil {
                Button {
                    if let url = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(url) }
                } label: {
                    Label(String(localized: "Open Settings", bundle: .module), systemImage: "gear")
                        .font(.subheadline.weight(.medium))
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
                .buttonStyle(.plain)
                .foregroundStyle(Color.storkPurple)
            }
        }
    }
}
#endif
