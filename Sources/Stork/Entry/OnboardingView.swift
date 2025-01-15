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
    
    var body: some View {
        VStack {
            Button(action: {
                withAnimation {
                    isOnboardingComplete = true
                    selectedTab = .home
                    appState = isPaywallComplete ? .main : .paywall

                }
            }, label: {
                Text("Skip Onboarding")
                    .foregroundStyle(.blue)
            })
            
            Spacer()
        }
        .padding()
    }
}

#Preview {
    OnboardingView()
}
