//
//  ProfileManagementView.swift
//  skipapp-stork
//
//  Created by Nick Molargik on 1/22/25.
//

import SwiftUI

struct ProfileManagementView: View {
    @Binding var isOnboardingComplete: Bool
    @Binding var appState: AppState
    @Binding var showingDeleteConfirmation: Bool

    var body: some View {
        Section(header: Text("Profile")) {
            HStack {
                Button(action: restartOnboarding) {
                    Text("Restart Onboarding")
                        .fontWeight(.bold)
                        .foregroundStyle(.indigo)
                }

                Spacer()

                Image(systemName: "book.fill")
                    .foregroundStyle(.indigo)
                    .frame(width: 30)
            }

            HStack {
                Button(action: {
                    triggerHaptic()
                    showingDeleteConfirmation = true
                }) {
                    Text("Delete Profile")
                        .fontWeight(.bold)
                        .foregroundStyle(.red)
                }

                Spacer()

                Image(systemName: "trash.fill")
                    .foregroundStyle(.red)
                    .frame(width: 30)
            }
        }
    }

    private func restartOnboarding() {
        triggerHaptic()
        withAnimation {
            isOnboardingComplete = false
            appState = .onboard
        }
    }
}

#Preview {
    ProfileManagementView(isOnboardingComplete: .constant(true), appState: .constant(.main), showingDeleteConfirmation: .constant(false))
}
