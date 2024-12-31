//
//  PaywallView.swift
//  skipapp-stork
//
//  Created by Nick Molargik on 12/30/24.
//

import SwiftUI

struct PaywallView: View {
    @AppStorage("appState") private var appState: AppState = .splash
    @AppStorage("selectedTab") var selectedTab = Tab.hospitals
    @AppStorage("isPaywallComplete") private var isPaywallComplete: Bool = false
    
    var body: some View {
        VStack {
            Button(action: {
                withAnimation {
                    isPaywallComplete = true
                    selectedTab = .home
                    appState = .main
                }
            }, label: {
                Text("Skip Onboarding")
                    .foregroundStyle(.blue)
            })
            
            Spacer()
        }
    }
}

#Preview {
    PaywallView()
}
