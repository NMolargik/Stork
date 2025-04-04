//
//  ProfileManagementView.swift
//  skipapp-stork
//
//  Created by Nick Molargik on 1/22/25.
//

import SwiftUI

struct ProfileManagementView: View {
    @AppStorage(StorageKeys.isOnboardingComplete) var isOnboardingComplete: Bool = false
    
    @EnvironmentObject var appStateManager: AppStateManager

    @Binding var showingProfileEditor: Bool
    @Binding var showingDeleteConfirmation: Bool

    var body: some View {
        Group {
            Button(action: {
                HapticFeedback.trigger(style: .medium)

                withAnimation {
                    showingProfileEditor = true
                }
            }, label: {
                HStack {
                    Text("Edit Profile")
                        .foregroundStyle(Color("storkOrange"))
                    
                    Spacer()
                    
                    Image("person.text.rectangle.fill", bundle: .module)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                        .foregroundStyle(Color("storkOrange"))
                }
            })
            
            Button(action: restartOnboarding) {
                HStack {
                    Text("Restart Onboarding")
                        .foregroundStyle(Color("storkIndigo"))
                    Spacer()
                    
                    Image("book.fill", bundle: .module)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                        .foregroundStyle(Color("storkIndigo"))
                }
            }

            Button(action: {
                HapticFeedback.trigger(style: .medium)
                showingDeleteConfirmation = true
            }) {
                HStack {
                    Text("Delete Profile")
                        .foregroundStyle(.red)
                    
                    Spacer()
                    
                    Image("trash.fill", bundle: .module)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                        .foregroundStyle(.red)
                }
            }
        }
    }

    private func restartOnboarding() {
        HapticFeedback.trigger(style: .medium)
        withAnimation {
            isOnboardingComplete = false
            appStateManager.currentAppScreen = .onboard
        }
    }
}

#Preview {
    ProfileManagementView(
        showingProfileEditor: .constant(false),
        showingDeleteConfirmation: .constant(false)
    )
    .environmentObject(AppStateManager.shared)
}
