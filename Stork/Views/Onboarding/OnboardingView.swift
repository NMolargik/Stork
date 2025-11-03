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

    @State private var viewModel: OnboardingView.ViewModel = .init()

    var body: some View {
        NavigationStack {
            ZStack {
                if viewModel.currentStep == .userInfo {
                    OnboardingUserInfoPage()
                        .transition(.asymmetric(insertion: .move(edge: .trailing),
                                                removal: .move(edge: .leading)))
                }
                if viewModel.currentStep == .location {
                    OnboardingLocationPage()
                        .transition(.asymmetric(insertion: .move(edge: .trailing),
                                                removal: .move(edge: .leading)))
                }
                if viewModel.currentStep == .health {
                    OnboardingHealthPage()
                        .transition(.asymmetric(insertion: .move(edge: .trailing),
                                                removal: .move(edge: .leading)))
                }
                if viewModel.currentStep == .complete {
                    OnboardingCompletePage(
                        onFinish: onFinished
                    )
                    .transition(.asymmetric(insertion: .move(edge: .trailing),
                                            removal: .move(edge: .leading)))
                }
            }
            .animation(.easeInOut(duration: 0.25), value: viewModel.currentStep)
            .navigationTitle(viewModel.currentStep.title)
            .navigationBarTitleDisplayMode(.large)
        }
        .task {
            viewModel.currentStep = .userInfo

            if let user = userManager.currentUser {
                viewModel.firstName = user.firstName
                viewModel.lastName = user.lastName
                viewModel.birthday = user.birthday
                viewModel.role = user.role
            }
        }
        .safeAreaInset(edge: .bottom) {
            if viewModel.currentStep != .complete {
                HStack {
                    if viewModel.showsSkip {
                        Button("Skip For Now") { viewModel.handleSkipTapped() }
                            .foregroundStyle(.white)
                            .padding()
                            .adaptiveGlass(tint: .storkOrange)
                    }
                    
                    Spacer()
                    
                    Button("Continue") { viewModel.handleContinueTapped(userManager: userManager) }
                        .foregroundStyle(.white)
                        .padding()
                        .adaptiveGlass(tint: (viewModel.canContinue && !viewModel.isSavingUser) ? .storkPurple : .gray)
                        .disabled(!viewModel.canContinue || viewModel.isSavingUser)
                }
                .bold()
                .padding(.horizontal)
                .padding(.top, 12)
                .padding(.bottom, 8)
                .background(.ultraThinMaterial)
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

    // Prepare a lightweight UserManager with the in-memory context
    let previewUserManager = UserManager(context: container.mainContext)
    let locationManager = LocationManager()
    let healthManager = HealthManager()

    return OnboardingView(onFinished: {})
        .environment(previewUserManager)
        .environment(locationManager)
        .environment(healthManager)
        .modelContainer(container)
}
