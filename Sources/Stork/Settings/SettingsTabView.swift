//
//  SettingsTabView.swift
//
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
                Section(header: Text("Profile")) {
                    HStack {
                        Button(action: {
                            triggerHaptic()
                            
                            withAnimation {
                                isOnboardingComplete = false
                                appState = AppState.onboard
                            }
                        }) {
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
                
                Section(header: Text("Preferences")) {
                    Toggle("Use Metric Units", isOn: $useMetric)
                        .tint(.green)
                    
                    Toggle("Dark Mode", isOn: $useDarkMode)
                        .tint(.green)
                }
                
                // New About Section
                Section(header: Text("Stork")) {
                    HStack {
                        Text("Version")
                        
                        Spacer()
                        
                        Text(appInfo.version)
                    }
                    
                    HStack {
                        Text("Developer")
                        
                        Spacer()

                        Link("Nick Molargik", destination: URL(string: "https://www.nickmolargik.tech")!)
                            .foregroundColor(.blue)
                            .underline(false)
                    }
                    
                    HStack {
                        Text("Multiplatform Technology")
                        
                        Spacer()
                        
                        Link(destination: URL(string: "https://skip.tools")!, label: {
                            Text("Skip")
                                .foregroundColor(.blue)
                        })

                    }
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem {
                    Button(action: {
                        triggerHaptic()

                        withAnimation {
                            profileViewModel.signOut()
                        }
                    }) {
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
                    onDelete: {
                        deleteAccount()
                    }
                )
                .interactiveDismissDisabled()
                .presentationDetents([.medium])
            }
        }
    }
    
    private func triggerHaptic() {
        #if !SKIP
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()
        #endif
    }
    
    /// Function to handle account deletion
    private func deleteAccount() {
        profileViewModel.isWorking = true
        
        Task {
            // Leave Muster
            if (!profileViewModel.profile.musterId.isEmpty) {
                do {
                    try await musterViewModel.leaveMuster(profileViewModel: profileViewModel)
                } catch {
                    profileViewModel.isWorking = false
                    errorMessage = error.localizedDescription
                    return
                }
            }
            
            do {
                try await profileViewModel.deleteProfile(password: passwordString)
            } catch {
                profileViewModel.isWorking = false
                errorMessage = error.localizedDescription
                return
            }
        }
    }
}

#Preview {
    SettingsTabView()
        .environmentObject(ProfileViewModel(profileRepository: MockProfileRepository()))
        .environmentObject(MusterViewModel(musterRepository: MockMusterRepository()))
}
