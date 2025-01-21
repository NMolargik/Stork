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
    
    // Callback invoked when onboarding finishes
    var onComplete: () -> Void
    
    // Local state to track which page is active
    @State private var currentPage: Int = 0
    
    // Total number of onboarding pages
    private let totalPages = 4
    
    var body: some View {
        VStack {
            // MARK: - Paged Onboarding Content
            TabView(selection: $currentPage) {
                // Generate 4 placeholder pages
                ForEach(0..<totalPages, id: \.self) { index in
                    VStack(spacing: 20) {
                        Text("Onboarding Step \(index + 1)")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text("This is some descriptive text for this step of onboarding. Customize and add more visuals or instructions as needed.")
                            .multilineTextAlignment(.center)
                            .padding()
                    }
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            
            // MARK: - Navigation Buttons (Skip / Next / Done)
            HStack {
                Button("Skip") {
                    // Immediately finish onboarding
                    finishOnboarding()
                }
                .foregroundStyle(.blue)
                
                Spacer()
                
                Button(currentPage < totalPages - 1 ? "Next" : "Done") {
                    if currentPage < totalPages - 1 {
                        // Move to next page
                        withAnimation {
                            currentPage += 1
                        }
                    } else {
                        // Done with onboarding
                        finishOnboarding()
                    }
                }
                .foregroundStyle(.blue)
            }
            .padding()
        }
    }
    
    // MARK: - Finish Onboarding
    private func finishOnboarding() {
        withAnimation {
            isOnboardingComplete = true
            selectedTab = .home
            appState = isPaywallComplete ? .main : .paywall
            
            // Invoke the onComplete callback for any additional logic
            onComplete()
        }
    }
}

#Preview {
    OnboardingView {
        // Example onComplete callback
        print("Onboarding completed!")
    }
}
