//
//  MainView.swift
//
//
//  Created by Nick Molargik on 11/28/24.
//

import StorkModel

#if !SKIP
import SwiftUI
#else
import SkipUI
#endif

public struct MainView: View {
    @AppStorage("selectedTab") var selectedTab = Tab.hospitals

    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var profileViewModel: ProfileViewModel
    @EnvironmentObject var deliveryViewModel: DeliveryViewModel
    
    @State private var navigationPath: [String] = []
    @State private var showingDeliveryAddition: Bool = false
    
    public var body: some View {
        TabView(selection: $selectedTab) {
            // HOME
            HomeTabView(navigationPath: $navigationPath, selectedTab: $selectedTab, showingDeliveryAddition: $showingDeliveryAddition)
                .tabItem {
                    Label(Tab.home.title, systemImage: Tab.home.icon)
                }
                .tag(Tab.home)
            
            // Deliveries
            DeliveryTabView(showingDeliveryAddition: $showingDeliveryAddition)
                .tabItem {
                    Label(Tab.deliveries.title, systemImage: Tab.deliveries.icon)
                }
                .tag(Tab.deliveries)
            
            // Hospitals
            HospitalListView(onSelection: { _ in })
                .tabItem {
                    Label(Tab.hospitals.title, systemImage: Tab.hospitals.icon)
                }
                .tag(Tab.hospitals)
            
            // Muster
            MusterTabView()
                .tabItem {
                    Label(Tab.muster.title, systemImage: Tab.muster.icon)
                }
                .tag(Tab.muster)
            
            // Settings
            SettingsTabView()
                .tabItem {
                    Label(Tab.settings.title, systemImage: Tab.settings.icon)
                }
                .tag(Tab.settings)
            
        }
        .tint(Color.indigo)
        .onAppear {
            withAnimation {
                deliveryViewModel.getDeliveries(userId: profileViewModel.profile.id)
                selectedTab = .home
            }
        }
    }
}

#Preview {
    MainView()
        .environmentObject(ProfileViewModel(profileRepository: MockProfileRepository()))
        .environmentObject(DeliveryViewModel(deliveryRepository: MockDeliveryRepository()))
        .environmentObject(MusterViewModel(musterRepository: MockMusterRepository()))
}
