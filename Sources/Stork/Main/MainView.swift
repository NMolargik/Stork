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
    @AppStorage("errorMessage") var errorMessage: String = ""
    @AppStorage("selectedTab") var selectedTab = Tab.hospitals

    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var profileViewModel: ProfileViewModel
    @EnvironmentObject var deliveryViewModel: DeliveryViewModel
    @EnvironmentObject var hospitalViewModel: HospitalViewModel
    @EnvironmentObject var musterViewModel: MusterViewModel

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
        .tint(colorScheme == .dark ? .white : .black)
        .onAppear {
            Task {
                do {
                    if profileViewModel.profile.id.isEmpty {
                        try await profileViewModel.fetchCurrentProfile()
                    }

                    if deliveryViewModel.deliveries.isEmpty {
                        try await deliveryViewModel.getUserDeliveries(profile: profileViewModel.profile)
                    }

                    if !profileViewModel.profile.musterId.isEmpty && musterViewModel.currentMuster == nil {
                        try await musterViewModel.loadCurrentMuster(profileViewModel: profileViewModel)
                    }
                } catch {
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}

#Preview {
    MainView()
        .environmentObject(ProfileViewModel(profileRepository: MockProfileRepository()))
        .environmentObject(DeliveryViewModel(deliveryRepository: MockDeliveryRepository()))
        .environmentObject(MusterViewModel(musterRepository: MockMusterRepository()))
        .environmentObject(HospitalViewModel(hospitalRepository: MockHospitalRepository(), locationProvider: MockLocationProvider()))
}
