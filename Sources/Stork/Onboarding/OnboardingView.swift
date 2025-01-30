//
//  OnboardingView.swift
//  skipapp-stork
//
//  Created by Nick Molargik on 12/30/24.
//

import SwiftUI
import StorkModel

struct OnboardingView: View {
    @AppStorage("appState") private var appState: AppState = .splash
    @AppStorage("selectedTab") var selectedTab = Tab.hospitals
    @AppStorage("isOnboardingComplete") private var isOnboardingComplete: Bool = false
    @AppStorage("loggedIn") private var loggedIn: Bool = false
    
    @State private var currentPage: Int = 0
    @State private var isTransitioning: Bool = false // NEW: Track transition state
    
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
            .padding([.horizontal, .bottom])
        }
        .animation(.easeInOut(duration: 0.5), value: isTransitioning) // NEW: Smooth animation
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
                isOnboardingComplete = true
                selectedTab = .home
                appState = Store.shared.subscriptionActive ? .main : .paywall
                onComplete()
            }
        }
    }
}

#Preview {
    OnboardingView {
        print("Onboarding completed!")
    }
}
