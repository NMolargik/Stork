//
//  MusterTabView.swift
//
//
//  Created by Nick Molargik on 11/29/24.
//

import SwiftUI

struct MusterTabView: View {
    @Binding var selectedTab: Tab
    @Binding var showingDeliveryAddition: Bool
    
    @State private var navigationPath: [String] = []

    
    var body: some View {
        VStack {
            NavigationStack(path: $navigationPath) {
                List {
//                    NavigationLink("Go to Details") {
//                        Text("Yet another details view")
//                    }
                    
                    Button("Go to shared profile view") {
                        navigationPath.append("ProfileView")
                    }
                }
                .navigationTitle("Muster")
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
}

#Preview {
    MusterTabView(selectedTab: .constant(.home), showingDeliveryAddition: .constant(false))
}
