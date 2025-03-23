//
//  TabControllerView.swift
//
//
//  Created by Nick Molargik on 11/28/24.
//

import SwiftUI
import StorkModel

public struct TabControllerView: View {
    @EnvironmentObject var appStateManager: AppStateManager
    
    @ObservedObject var profileViewModel: ProfileViewModel
    @ObservedObject var hospitalViewModel: HospitalViewModel
    @ObservedObject var deliveryViewModel: DeliveryViewModel
    @ObservedObject var musterViewModel: MusterViewModel

    public var body: some View {
        TabView(selection: $appStateManager.selectedTab) {
            HomeTabView(deliveryViewModel: deliveryViewModel)
                .tabItem {
                    VStack {
                        Image(Tab.home.customIconName, bundle: .module)
                        Text(Tab.home.title)
                    }
                }
                .tag(Tab.home)
                .environmentObject(appStateManager)

            DeliveryTabView(
                deliveryViewModel: deliveryViewModel,
                profileViewModel: profileViewModel,
                hospitalViewModel: hospitalViewModel,
                musterViewModel: musterViewModel
            )
            .tabItem {
                VStack {
                    Image(Tab.deliveries.customIconName, bundle: .module)
                    Text(Tab.deliveries.title)
                }
            }
            .tag(Tab.deliveries)
            .environmentObject(appStateManager)

            HospitalListView(
                hospitalViewModel: hospitalViewModel,
                profileViewModel: profileViewModel,
                onSelection: { _ in }
            )
            .tabItem {
                VStack {
                    Image(Tab.hospitals.customIconName, bundle: .module)
                    Text(Tab.hospitals.title)
                }
            }
            .tag(Tab.hospitals)
            .environmentObject(appStateManager)

            MusterTabView(
                profileViewModel: profileViewModel,
                musterViewModel: musterViewModel,
                deliveryViewModel: deliveryViewModel,
                hospitalViewModel: hospitalViewModel
            )
            .tabItem {
                VStack {
                    Image(Tab.muster.customIconName, bundle: .module)
                    Text(Tab.muster.title)
                }
            }
            .tag(Tab.muster)
            .environmentObject(appStateManager)

            SettingsTabView(
                profileViewModel: profileViewModel,
                musterViewModel: musterViewModel,
                deliveryViewModel: deliveryViewModel,
                hospitalViewModel: hospitalViewModel
            )
            .tabItem {
                VStack {
                    Image(Tab.settings.customIconName, bundle: .module)
                    Text(Tab.settings.title)
                }
            }
            .tag(Tab.settings)
            .environmentObject(appStateManager)

        }
        .foregroundStyle(.black)
        .tint(Color("storkIndigo"))
        .onChange(of: appStateManager.selectedTab) { _ in
            HapticFeedback.trigger(style: .medium)
        }
    }
}

// MARK: - Preview
#Preview {
    TabControllerView(
        profileViewModel: ProfileViewModel(profileRepository: MockProfileRepository(), appStorageManager: AppStorageManager()),
        hospitalViewModel: HospitalViewModel(hospitalRepository: DefaultHospitalRepository(remoteDataSource: FirebaseHospitalDatasource()), locationProvider: LocationProvider()),
        deliveryViewModel: DeliveryViewModel(deliveryRepository: DefaultDeliveryRepository(remoteDataSource: FirebaseDeliveryDataSource())),
        musterViewModel: MusterViewModel(musterRepository: DefaultMusterRepository(remoteDataSource: FirebaseMusterDataSource()))
    )
    .environmentObject(AppStateManager.shared)
}
