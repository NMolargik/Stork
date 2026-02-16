//
//  OnboardingView.swift
//  Stork
//
//  Created by Nick Molargik on 10/2/25.
//

import SwiftUI
import SwiftData

struct OnboardingView: View {
    @Environment(LocationManager.self) private var locationManager
    @Environment(HealthManager.self) private var healthManager
    
    var onFinished: () -> Void = {}

    @State private var viewModel = ViewModel()

    private var steps: [OnboardingStep] {
        OnboardingStep.allCases.filter { step in
            if step == .health, UIDevice.current.userInterfaceIdiom == .pad {
                return false
            }
            return true
        }
    }

    private var currentIndex: Int {
        steps.firstIndex(of: viewModel.currentStep) ?? 0
    }

    var body: some View {
        VStack(spacing: 0) {
            // Page Indicators
            if viewModel.currentStep != .complete {
                HStack(spacing: 8) {
                    ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                        Capsule()
                            .fill(index <= currentIndex ? Color.storkPurple : Color.secondary.opacity(0.3))
                            .frame(height: 4)
                            .animation(.easeInOut(duration: 0.3), value: currentIndex)
                    }
                }
                .frame(maxWidth: 500)
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .padding(.bottom, 8)
            }

            // Content
            TabView(selection: $viewModel.currentStep) {
                OnboardingPrivacyPage()
                    .tag(OnboardingStep.privacy)

                OnboardingLocationPage()
                    .tag(OnboardingStep.location)

                if UIDevice.current.userInterfaceIdiom != .pad {
                    OnboardingHealthPage()
                        .tag(OnboardingStep.health)
                }

                OnboardingCompletePage(onFinish: onFinished)
                    .tag(OnboardingStep.complete)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut(duration: 0.3), value: viewModel.currentStep)

            // Bottom Buttons
            if viewModel.currentStep != .complete {
                VStack(spacing: 12) {
                    // Continue Button
                    Button {
                        Haptics.mediumImpact()
                        Task {
                            await viewModel.handleContinueTapped(
                                locationManager: locationManager,
                                healthManager: healthManager
                            )
                        }
                    } label: {
                        HStack(spacing: 8) {
                            if viewModel.isRequestingPermission {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text("Continue")
                                    .font(.headline)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(viewModel.canContinue ? Color.storkPurple : Color.secondary.opacity(0.3))
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .disabled(!viewModel.canContinue)
                }
                .frame(maxWidth: 500)
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
                .padding(.top, 12)
                .frame(maxWidth: .infinity)
                .background(.ultraThinMaterial)
            }
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .task {
            viewModel.currentStep = .privacy
        }
        .environment(viewModel)
    }
}

#Preview("Onboarding Flow") {
    let container: ModelContainer
    do {
        container = try ModelContainer(
            for: Delivery.self, Baby.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
    } catch {
        fatalError("Preview ModelContainer setup failed: \(error)")
    }

    let locationManager = LocationManager()
    let healthManager = HealthManager()

    return OnboardingView(onFinished: {})
        .environment(locationManager)
        .environment(healthManager)
        .modelContainer(container)
}
