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
            tabItem(for: .home) {
                HomeTabView(navigationPath: $navigationPath, selectedTab: $selectedTab, showingDeliveryAddition: $showingDeliveryAddition)
            }
            
            tabItem(for: .deliveries) {
                DeliveryTabView(showingDeliveryAddition: $showingDeliveryAddition)
            }
            
            tabItem(for: .hospitals) {
                HospitalListView(onSelection: { _ in })
            }
            
            tabItem(for: .muster) {
                MusterTabView()
            }
            
            tabItem(for: .settings) {
                SettingsTabView()
            }
        }
        .tint(.indigo)
        .onChange(of: selectedTab) { _ in
            triggerHaptic()
        }
    }
    
    func tabItem<Content: View>(for tab: Tab, @ViewBuilder content: () -> Content) -> some View {
        content()
            .tabItem {
                Label(tab.title, systemImage: tab.icon)
            }
            .tag(tab)
    }
}

// MARK: - Preview
#Preview {
    MainView()
        .withMockEnvironmentObjects()
}

// MARK: - Environment Object Injection
private extension View {
    func withMockEnvironmentObjects() -> some View {
        self
            .environmentObject(ProfileViewModel(profileRepository: MockProfileRepository()))
            .environmentObject(DeliveryViewModel(deliveryRepository: MockDeliveryRepository()))
            .environmentObject(MusterViewModel(musterRepository: MockMusterRepository()))
            .environmentObject(HospitalViewModel(hospitalRepository: MockHospitalRepository(), locationProvider: MockLocationProvider()))
    }
}
