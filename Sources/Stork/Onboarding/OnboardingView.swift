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
    @AppStorage("isPaywallComplete") private var isPaywallComplete: Bool = false
    @AppStorage("loggedIn") private var loggedIn: Bool = false
    
    @State private var currentPage: Int = 0
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
            
            HStack {
                CustomButtonView(
                    text: "Skip Onboarding",
                    width: 170, height: 50,
                    color: .orange, isEnabled: true,
                    onTapAction: finishOnboarding
                )

                Spacer()

                CustomButtonView(
                    text: isLastPage ? "Done" : "Next",
                    width: 110, height: 50,
                    color: .indigo, isEnabled: true,
                    onTapAction: nextPage
                )
            }
            .padding([.horizontal, .bottom])
        }
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
            isOnboardingComplete = true
            selectedTab = .home
            appState = isPaywallComplete ? .main : .paywall
            onComplete()
        }
    }
}

#Preview {
    OnboardingView {
        print("Onboarding completed!")
    }
}
