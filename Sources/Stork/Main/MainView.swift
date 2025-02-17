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
                MusterTabView(
                    showingDeliveryAddition: $showingDeliveryAddition,
                    selectedTab: $selectedTab
                )
            }
            
            tabItem(for: .settings) {
                SettingsTabView()
            }
        }
        .tint(Color("storkIndigo"))
        .onChange(of: selectedTab) { _ in
            triggerHaptic()
        }
    }
    
    func tabItem<Content: View>(for tab: Tab, @ViewBuilder content: () -> Content) -> some View {
        content()
            .tabItem {
                VStack {
                    Image(tab.customIconName)
                    
                    Text(tab.title)
                }
            }
            .tag(tab)
    }
}

// MARK: - Preview
#Preview {
    MainView()
        .withMockEnvironmentObjects()
}
