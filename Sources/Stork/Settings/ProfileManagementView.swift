//
//  ProfileManagementView.swift
//  skipapp-stork
//
//  Created by Nick Molargik on 1/22/25.
//

import SwiftUI

struct ProfileManagementView: View {
    @EnvironmentObject var appStorageManager: AppStorageManager
    @EnvironmentObject var appStateManager: AppStateManager

    @Binding var showingProfileEditor: Bool
    @Binding var showingDeleteConfirmation: Bool

    var body: some View {
        Section(header: Text("Profile")) {
            HStack {
                Button(action: {
                    HapticFeedback.trigger(style: .medium)

                    withAnimation {
                        showingProfileEditor = true
                    }
                }, label: {
                    Text("Edit Profile")
                        .foregroundStyle(Color("storkOrange"))
                })
                
                Spacer()

                Image("person.text.rectangle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .foregroundStyle(Color("storkOrange"))
            }
            HStack {
                Button(action: restartOnboarding) {
                    Text("Restart Onboarding")
                        .foregroundStyle(Color("storkIndigo"))
                }

                Spacer()

                Image("book.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .foregroundStyle(Color("storkIndigo"))
            }

            HStack {
                Button(action: {
                    HapticFeedback.trigger(style: .medium)
                    showingDeleteConfirmation = true
                }) {
                    Text("Delete Profile")
                        .foregroundStyle(.red)
                }

                Spacer()

                Image("trash.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .foregroundStyle(.red)
            }
        }
    }

    private func restartOnboarding() {
        HapticFeedback.trigger(style: .medium)
        withAnimation {
            appStorageManager.isOnboardingComplete = false
            appStateManager.currentAppScreen = .onboard
        }
    }
}

#Preview {
    ProfileManagementView(
        showingProfileEditor: .constant(false),
        showingDeleteConfirmation: .constant(false)
    )
    .environmentObject(AppStorageManager())
    .environmentObject(AppStateManager.shared)
}
