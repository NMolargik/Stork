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
    @Binding var showingProfileEditor: Bool
    @Binding var showingDeleteConfirmation: Bool


    var body: some View {
        Section(header: Text("Profile")) {
            HStack {
                Button(action: {
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
                    triggerHaptic()
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
        triggerHaptic()
        withAnimation {
            isOnboardingComplete = false
            appState = .onboard
        }
    }
}

#Preview {
    ProfileManagementView(isOnboardingComplete: .constant(true), appState: .constant(.main), showingProfileEditor: .constant(false), showingDeleteConfirmation: .constant(false))
}
