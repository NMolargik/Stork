//
//  OnboardingView.swift
//  Stork
//
//  Created by Nick Molargik on 10/2/25.
//

import SwiftUI
import SwiftData

struct OnboardingView: View {
    @Environment(UserManager.self) private var userManager: UserManager

    var onFinished: () -> Void = {}

    @State private var viewModel = ViewModel()

    private var steps: [OnboardingStep] {
        OnboardingStep.allCases
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
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .padding(.bottom, 8)
            }

            // Content
            TabView(selection: $viewModel.currentStep) {
                OnboardingPrivacyPage()
                    .tag(OnboardingStep.privacy)

                OnboardingUserInfoPage()
                    .tag(OnboardingStep.userInfo)

                OnboardingLocationPage()
                    .tag(OnboardingStep.location)

                OnboardingHealthPage()
                    .tag(OnboardingStep.health)

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
                        viewModel.handleContinueTapped(userManager: userManager)
                    } label: {
                        HStack(spacing: 8) {
                            if viewModel.isSavingUser {
                                ProgressView()
                                    .tint(.white)
                            }
                            Text(viewModel.currentStep == .userInfo && viewModel.isSavingUser ? "Saving..." : "Continue")
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(viewModel.canContinue && !viewModel.isSavingUser ? Color.storkPurple : Color.secondary.opacity(0.3))
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .disabled(!viewModel.canContinue || viewModel.isSavingUser)

                    // Skip Button (optional steps only)
                    if viewModel.showsSkip {
                        Button {
                            Haptics.lightImpact()
                            viewModel.handleSkipTapped()
                        } label: {
                            Text("Skip for now")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
                .padding(.top, 12)
                .background(.ultraThinMaterial)
            }
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .task {
            viewModel.currentStep = .privacy

            if let user = userManager.currentUser {
                viewModel.firstName = user.firstName
                viewModel.lastName = user.lastName
                viewModel.birthday = user.birthday
                viewModel.role = user.role
            }
        }
        .environment(viewModel)
    }
}

#Preview("Onboarding Flow") {
    let container: ModelContainer
    do {
        container = try ModelContainer(
            for: User.self, Delivery.self, Baby.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
    } catch {
        fatalError("Preview ModelContainer setup failed: \(error)")
    }

    let previewUserManager = UserManager(context: container.mainContext)
    let locationManager = LocationManager()
    let healthManager = HealthManager()

    return OnboardingView(onFinished: {})
        .environment(previewUserManager)
        .environment(locationManager)
        .environment(healthManager)
        .modelContainer(container)
}
