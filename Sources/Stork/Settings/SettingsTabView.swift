//
//  SettingsTabView.swift
//  skipapp-stork
//
//  Created by Nick Molargik on 11/30/24.
//

import SwiftUI
import StorkModel

struct SettingsTabView: View {
    @AppStorage("useMetric") private var useMetric: Bool = false
    @AppStorage("useDarkMode") private var useDarkMode: Bool = false
    @AppStorage("appState") private var appState: AppState = .splash
    @AppStorage("isOnboardingComplete") private var isOnboardingComplete: Bool = false
    @AppStorage("errorMessage") var errorMessage: String = ""

    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var profileViewModel: ProfileViewModel
    @EnvironmentObject var musterViewModel: MusterViewModel
    @EnvironmentObject var deliveryViewModel: DeliveryViewModel

    @State private var showingDeleteConfirmation = false
    @State private var deleteConfirmationStep = 1
    @State private var passwordString: String = ""

    private var appInfo: (name: String, version: String) {
        let name = Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String ??
                   Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String ??
                   "App Name"
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        return (name, version)
    }

    var body: some View {
        NavigationStack {
            List {
                ProfileManagementView(
                    isOnboardingComplete: $isOnboardingComplete,
                    appState: $appState,
                    showingDeleteConfirmation: $showingDeleteConfirmation
                )

                PreferencesView(useMetric: $useMetric, useDarkMode: $useDarkMode)

                AboutView(appInfo: appInfo)
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem {
                    Button(action: signOut) {
                        Text("Sign Out")
                            .fontWeight(.bold)
                            .foregroundStyle(.orange)
                    }
                }
            }
            .sheet(isPresented: $showingDeleteConfirmation) {
                DeleteConfirmationView(
                    step: $deleteConfirmationStep,
                    showing: $showingDeleteConfirmation,
                    onDelete: handleAccountDeletion
                )
                .interactiveDismissDisabled()
                .presentationDetents([.medium])
            }
        }
    }
    
    func signOut() {
        triggerHaptic()
        withAnimation {
            profileViewModel.signOut()
        }
    }

    func handleAccountDeletion() {
        profileViewModel.isWorking = true

        Task {
            do {
                // Leave Muster if applicable
                if !profileViewModel.profile.musterId.isEmpty {
                    try await musterViewModel.leaveMuster(
                        profileViewModel: profileViewModel,
                        deliveryViewModel: deliveryViewModel
                    )
                }

                // Delete profile
                try await profileViewModel.deleteProfile(password: passwordString)

            } catch {
                profileViewModel.isWorking = false
                errorMessage = error.localizedDescription
            }
        }
    }
}

// MARK: - Preview
#Preview {
    SettingsTabView()
        .environmentObject(ProfileViewModel(profileRepository: MockProfileRepository()))
        .environmentObject(MusterViewModel(musterRepository: MockMusterRepository()))
        .environmentObject(DeliveryViewModel(deliveryRepository: MockDeliveryRepository()))
}
