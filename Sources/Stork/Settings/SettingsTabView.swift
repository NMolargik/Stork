//
//  SettingsTabView.swift
//
//
//  Created by Nick Molargik on 11/30/24.
//

import SwiftUI
import StorkModel

struct SettingsTabView: View {
    @AppStorage("useMetricUnits") var useMetricUnits = false
    
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var profileViewModel: ProfileViewModel
    @Binding var navigationPath: [String]
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            List {
                Section("Profile", content: {
                    Button(action: {
                        withAnimation {
                            profileViewModel.signOut()
                        }
                    }, label: {
                        Text("Sign Out")
                            .foregroundStyle(.red)
                    })
                    
                    HStack {
                        Button(action: {
                            // TODO: this
                        }, label: {
                            Text("Delete Account")
                                .foregroundStyle(colorScheme == .dark ? Color.white : Color.black)
                        })
                        
                        Spacer()
                        
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundStyle(.yellow)
                    }
                })
                
                Section("Units", content: {
                    Toggle("Use Metric Units", isOn: $useMetricUnits)
                    
                    //TODO: use this throughout the app!
                })
            }
            .navigationTitle("Settings")
            .navigationDestination(for: String.self) { value in
                if value == "ProfileView" {
                    Text("Shared Profile View")
                } else {
                    Text("Other View: \(value)")
                }
            }
        }
    }
}

#Preview {
    SettingsTabView(navigationPath: .constant([]))
        .environmentObject(ProfileViewModel(profileRepository: MockProfileRepository()))
}
