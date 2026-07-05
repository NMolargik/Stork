//
//  OnboardingView.swift
//  StorkFeatureOnboarding
//
//  Paged onboarding: privacy → location → (step count) → complete, with inline permission
//  requests. The Step Count page is skipped where it can't work (Mac/Vision).
//

#if os(iOS)
import SwiftUI
import StorkCore
import StorkDesignSystem
import StorkServices

public struct OnboardingView: View {
    @Environment(LocationManager.self) private var locationManager
    @Environment(HealthManager.self) private var healthManager

    private let onFinished: () -> Void
    @State private var model = OnboardingModel()

    public init(onFinished: @escaping () -> Void = {}) {
        self.onFinished = onFinished
    }

    private var steps: [OnboardingStep] {
        healthManager.isStepTrackingSupported
            ? OnboardingStep.allCases
            : OnboardingStep.allCases.filter { $0 != .health }
    }

    private var currentIndex: Int {
        steps.firstIndex(of: model.currentStep) ?? 0
    }

    public var body: some View {
        VStack(spacing: 0) {
            if model.currentStep != .complete {
                HStack(spacing: 8) {
                    ForEach(Array(steps.enumerated()), id: \.offset) { index, _ in
                        Capsule()
                            .fill(index <= currentIndex ? Color.storkPurple : Color.secondary.opacity(0.3))
                            .frame(height: 4)
                            .animation(.easeInOut(duration: 0.3), value: currentIndex)
                    }
                }
                .frame(maxWidth: 500)
                .padding(.horizontal, 24).padding(.top, 16).padding(.bottom, 8)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Step \(currentIndex + 1) of \(steps.count)")
            }

            TabView(selection: $model.currentStep) {
                OnboardingPrivacyPage().tag(OnboardingStep.privacy)
                OnboardingLocationPage().tag(OnboardingStep.location)
                if healthManager.isStepTrackingSupported {
                    OnboardingHealthPage().tag(OnboardingStep.health)
                }
                OnboardingCompletePage(onFinish: onFinished).tag(OnboardingStep.complete)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut(duration: 0.3), value: model.currentStep)

            if model.currentStep != .complete {
                VStack(spacing: 12) {
                    Button {
                        Haptics.mediumImpact()
                        Task { await model.handleContinueTapped(locationManager: locationManager, healthManager: healthManager) }
                    } label: {
                        HStack(spacing: 8) {
                            if model.isRequestingPermission {
                                ProgressView().tint(.white)
                            } else {
                                Text("Continue").font(.headline)
                            }
                        }
                        .frame(maxWidth: .infinity).frame(height: 38)
                    }
                    .buttonStyle(.glassProminent)
                    .controlSize(.large)
                    .tint(.storkPurple)
                    .disabled(!model.canContinue)
                }
                .frame(maxWidth: 500)
                .padding(.horizontal, 24).padding(.bottom, 24).padding(.top, 12)
                .frame(maxWidth: .infinity)
                .background(.ultraThinMaterial)
            }
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .task { model.currentStep = .privacy }
    }
}
#endif
