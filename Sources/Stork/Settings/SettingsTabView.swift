//
//  SettingsTabView.swift
//
//
//  Created by Nick Molargik on 11/30/24.
//

import SwiftUI

struct SettingsTabView: View {
    @Binding var navigationPath: [String]
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            List {
//                        NavigationLink("Go to Details", destination: Text("Jesus, another details view?"))
                
                Button("Go to shared profile view") {
                    navigationPath.append("ProfileView")
                }
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
}
