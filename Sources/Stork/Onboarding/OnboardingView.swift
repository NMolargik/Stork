//
//  OnboardingView.swift
//  skipapp-stork
//
//  Created by Nick Molargik on 12/30/24.
//

import SwiftUI
import StorkModel

struct OnboardingView: View {
    @EnvironmentObject var appStateManager: AppStateManager
    @EnvironmentObject var appStorageManager: AppStorageManager
    
    @State private var currentPage: Int = 0
    @State private var isTransitioning: Bool = false
    
    // Completion callback from parent
    var onComplete: () -> Void

    private let totalPages = 3
    private var isLastPage: Bool { currentPage == totalPages - 1 }
    
    var body: some View {
        VStack {
            // MARK: - Paged Onboarding Content
            TabView(selection: $currentPage) {
                Group {
                    switch currentPage {
                    case 0: OnboardingPageOneView()
                    case 1: OnboardingPageTwoView()
                    case 2: OnboardingPageThreeView()
                    default: OnboardingPageOneView()
                    }
                }
                .tag(currentPage)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .padding()
            .opacity(isTransitioning ? 0.0 : 1.0)

            HStack {
                CustomButtonView(
                    text: "Skip Onboarding",
                    width: 170, height: 50,
                    color: Color("storkOrange"), isEnabled: true,
                    onTapAction: finishOnboarding
                )

                Spacer()

                CustomButtonView(
                    text: isLastPage ? "Enter Stork" : "Next",
                    width: 110, height: 50,
                    color: Color("storkIndigo"), isEnabled: true,
                    onTapAction: nextPage
                )
            }
            .padding(.horizontal)
            .frame(height: 80)
            #if SKIP
            .padding(.bottom, 60)
            #endif
        }
        .animation(.easeInOut(duration: 0.5), value: isTransitioning) // Smooth animation
    }

    private func nextPage() {
        withAnimation {
            if isLastPage {
                finishOnboarding()
            } else {
                currentPage += 1
            }
        }
    }

    private func finishOnboarding() {
        withAnimation {
            isTransitioning = true // Start fade out
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { // Wait for animation
            withAnimation {
                // Update global state via environment objects
                appStorageManager.isOnboardingComplete = true
                appStateManager.selectedTab = .home
                
                //TODO: Repair Android
                #if !SKIP
                appStateManager.currentAppScreen = Store.shared.subscriptionActive ? .main : .paywall
                #else
                appStateManager.currentAppScreen = .main
                #endif
                onComplete()
            }
        }
    }
}

#Preview {
    OnboardingView {
        print("Onboarding completed!")
    }
    .environmentObject(AppStateManager.shared)
    .environmentObject(AppStorageManager())
}
