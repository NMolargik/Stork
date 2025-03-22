//
//  SettingsTabView.swift
//  skipapp-stork
//
//  Created by Nick Molargik on 11/30/24.
//

import SwiftUI
import StorkModel

struct SettingsTabView: View {
    @Environment(\.colorScheme) var colorScheme
    
    @EnvironmentObject var appStateManager: AppStateManager
    @EnvironmentObject var appStorageManager: AppStorageManager

    @ObservedObject var profileViewModel: ProfileViewModel
    @ObservedObject var musterViewModel: MusterViewModel
    @ObservedObject var deliveryViewModel: DeliveryViewModel
    @ObservedObject var hospitalViewModel: HospitalViewModel

    @State private var showingDeleteConfirmation = false
    @State private var deleteConfirmationStep = 1
    @State private var passwordString: String = ""
    @State private var showingProfileEditor: Bool = false

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
                    showingProfileEditor: $showingProfileEditor,
                    showingDeleteConfirmation: $showingDeleteConfirmation
                )

                PreferencesView()

                AboutView(appInfo: appInfo)
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem {
                    Button(action: signOut) {
                        Text("Sign Out")
                            .fontWeight(.bold)
                            .foregroundStyle(Color("storkOrange"))
                    }
                }
            }
            .sheet(isPresented: $showingProfileEditor, content: {
                ProfileView(profileViewModel: profileViewModel)
                    .interactiveDismissDisabled()
                    .presentationDetents([.fraction(0.75)])
            })
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
        HapticFeedback.trigger(style: .medium)

        deliveryViewModel.reset()
        hospitalViewModel.reset()
        musterViewModel.reset()
        
        withAnimation {
            profileViewModel.signOut()
        }
    }

    func handleAccountDeletion() {
        profileViewModel.isWorking = true

        Task {
            do {
                if !profileViewModel.profile.musterId.isEmpty {
                    try await musterViewModel.leaveMuster(
                        profileViewModel: profileViewModel,
                        deliveryViewModel: deliveryViewModel
                    )
                }

                // Delete profile
                try await profileViewModel.deleteProfile(password: passwordString)
                
                //TODO: Future - actually delete user's account, not just their data
                // Requires updates to skip firebase

            } catch {
                withAnimation {
                    profileViewModel.isWorking = false
                    appStateManager.errorMessage = error.localizedDescription
                }
            }
        }
    }
}

// MARK: - Preview
#Preview {
    SettingsTabView(
        profileViewModel: ProfileViewModel(profileRepository: MockProfileRepository(), appStorageManager: AppStorageManager()),
        musterViewModel: MusterViewModel(musterRepository: MockMusterRepository()),
        deliveryViewModel: DeliveryViewModel(deliveryRepository: MockDeliveryRepository()),
        hospitalViewModel: HospitalViewModel(hospitalRepository: MockHospitalRepository(), locationProvider: MockLocationProvider())
    )
    .environmentObject(AppStateManager.shared)
    .environmentObject(AppStorageManager())
}
