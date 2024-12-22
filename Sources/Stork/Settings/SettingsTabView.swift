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
    @AppStorage("appState") private var appState: AppState = .splash
    
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var profileViewModel: ProfileViewModel
    
    @State private var showingDeleteConfirmation = false
    @State private var deleteConfirmationStep = 1
    
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
                            withAnimation {
                                appState = AppState.onboard
                                //TODO: fix, this doesn't kick back to onboarding
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
                            showingDeleteConfirmation = true
                        }) {
                            Text("Delete Account")
                                .fontWeight(.bold)
                                .foregroundStyle(.red)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "trash.fill")
                            .foregroundStyle(.red)
                            .frame(width: 30)
                    }
                }
                
                Section(header: Text("Units")) {
                    Toggle("Use Metric Units", isOn: $useMetric)
                        .tint(.green)
                }
                
                // New About Section
                Section(header: Text("Stork")) {
                    HStack {
                        Text("Version:")
                        
                        Spacer()
                        
                        Text(appInfo.version)
                    }
                    
                    HStack {
                        Text("Developer:")
                        
                        Spacer()

                        Link("Nick Molargik", destination: URL(string: "https://www.nickmolargik.tech")!)
                            .foregroundColor(.blue)
                            .underline(false)
                    }
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem {
                    Button(action: {
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
            }
        }
    }
    
    /// Function to handle account deletion
    private func deleteAccount() {
        // TODO: Add account deletion logic here
        // For example:
        // profileViewModel.deleteAccount()
        // deliveryViewModel.deleteAllDeliveries()
        
        // After deletion, navigate the user to splash screen
    }
}

#Preview {
    SettingsTabView()
        .environmentObject(ProfileViewModel(profileRepository: MockProfileRepository()))
}


struct DeleteConfirmationView: View {
    @Binding var step: Int
    @Binding var showing: Bool
    var onDelete: () -> Void
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                if step == 1 {
                    Text("Are you sure you want to delete your account?")
                        .font(.headline)
                        .multilineTextAlignment(.center)
                        .padding()
                    
                    Text("This action will permanently delete all your personal information and your deliveries.")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding([.leading, .trailing])
                    
                    HStack(spacing: 40) {
                        Button(action: {
                            // Cancel deletion
                            showing = false
                            step = 1
                        }) {
                            Text("Cancel")
                                .foregroundColor(.red)
                        }
                        
                        Button(action: {
                            // Proceed to step 2
                            step = 2
                        }) {
                            Text("Continue")
                                .foregroundColor(.blue)
                        }
                    }
                } else if step == 2 {
                    Text("Are you absolutely sure you want to delete your account?")
                        .font(.headline)
                        .multilineTextAlignment(.center)
                        .padding()
                    
                    Text("This will remove all your personal data and cannot be undone.")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding([.leading, .trailing])
                    
                    HStack(spacing: 40) {
                        Button(action: {
                            // Cancel deletion
                            showing = false
                            step = 1
                        }) {
                            Text("Cancel")
                                .foregroundColor(.red)
                        }
                        
                        Button(action: {
                            // Confirm deletion
                            onDelete()
                            showing = false
                            step = 1
                        }) {
                            Text("Delete")
                                .foregroundColor(.red)
                        }
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Confirm Deletion")
        }
    }
}
