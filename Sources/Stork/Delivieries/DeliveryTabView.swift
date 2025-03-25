//
//  DeliveryTabView.swift
//
//  Created by Nick Molargik on 11/30/24.
//

import SwiftUI
import StorkModel

@MainActor
struct DeliveryTabView: View {
    @EnvironmentObject var appStateManager: AppStateManager
    @EnvironmentObject var appStorageManager: AppStorageManager
    
    @StateObject private var dailyResetUtility = DailyResetUtility()
    
    @ObservedObject var deliveryViewModel: DeliveryViewModel
    @ObservedObject var profileViewModel: ProfileViewModel
    @ObservedObject var hospitalViewModel: HospitalViewModel
    @ObservedObject var musterViewModel: MusterViewModel

    var body: some View {
        NavigationStack(path: $appStateManager.navigationPath) {
            DeliveryListView(
                deliveryViewModel: deliveryViewModel,
                profileViewModel: profileViewModel
            )
            .refreshable { await refreshDeliveries() }
            .navigationTitle("Deliveries")
            .navigationDestination(for: Delivery.self) { delivery in
                if let foundDelivery = deliveryViewModel.findDelivery(by: delivery.id) {
                    DeliveryDetailView(delivery: foundDelivery)
                } else {
                    Text("Delivery not found")
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if dailyResetUtility.canSubmitDelivery() {
                        Button(action: {
                            withAnimation {
                                HapticFeedback.trigger(style: .medium)
                                appStateManager.showingDeliveryAddition = true
                            }
                        }) {
                            Text("New Delivery")
                                .foregroundStyle(Color("storkOrange"))
                                .fontWeight(.bold)
                        }
                    } else {
                        Text("Daily Limit Reached")
                            .foregroundStyle(Color.red)
                            .fontWeight(.bold)
                    }
                }
                ToolbarItem(placement: .topBarLeading) {
                    if deliveryViewModel.hasMorePages {
                        Button(action: {
                            withAnimation {
                                loadMoreDeliveries()
                            }
                        }, label: {
                            Text("Load More")
                                .fontWeight(.bold)
                                .foregroundStyle(Color("storkIndigo"))
                        })
                    }
                }
            }
            .sheet(isPresented: $appStateManager.showingDeliveryAddition) {
                NavigationStack {
                    DeliveryAdditionView(
                        profileViewModel: profileViewModel,
                        deliveryViewModel: deliveryViewModel,
                        hospitalViewModel: hospitalViewModel,
                        musterViewModel: musterViewModel,
                        dailyResetUtility: dailyResetUtility
                    )
                        .toolbar {
                            ToolbarItem(placement: .navigationBarLeading) {
                                Text("New Delivery")
                                    .fontWeight(.bold)
                                    .foregroundStyle(appStorageManager.useDarkMode ? Color.white : Color.black)
                            }
                            
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button(action: {
                                    HapticFeedback.trigger(style: .medium)
                                    withAnimation {
                                        appStateManager.showingDeliveryAddition = false
                                    }
                                }) {
                                    Text("Cancel")
                                        .fontWeight(.bold)
                                        .foregroundStyle(.red)
                                }
                            }
                        }
                        .environmentObject(dailyResetUtility)
                }
                .animation(.easeInOut, value: appStateManager.showingDeliveryAddition)
                .interactiveDismissDisabled()
            }
            .onChange(of: appStateManager.showingDeliveryAddition) { newValue in
                    print(newValue)
            }
        }
    }

    // MARK: - Refresh Deliveries
    private func refreshDeliveries() async {
        deliveryViewModel.currentPage = 0
        deliveryViewModel.deliveries.removeAll()
        deliveryViewModel.groupedDeliveries.removeAll()
        deliveryViewModel.hasMorePages = true
        deliveryViewModel.lastFetchedEndDate = nil

        do {
            try await deliveryViewModel.fetchNextDeliveries(profile: profileViewModel.profile)
        } catch {
            withAnimation {
                appStateManager.errorMessage = "Failed to refresh deliveries: \(error.localizedDescription)"
            }
        }
    }
    
    // MARK: - Load More Deliveries
    private func loadMoreDeliveries() {
        Task {
            do {
                let initialCount = deliveryViewModel.deliveries.count
                try await deliveryViewModel.fetchNextDeliveries(profile: profileViewModel.profile)
                
                let newCount = deliveryViewModel.deliveries.count
                if newCount > initialCount {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        deliveryViewModel.groupDeliveries()
                    }
                }
            } catch {
                print("Error loading more deliveries: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - Preview
#Preview {
    DeliveryTabView(
        deliveryViewModel: DeliveryViewModel(deliveryRepository: MockDeliveryRepository()),
        profileViewModel: ProfileViewModel(profileRepository: MockProfileRepository(), appStorageManager: AppStorageManager()),
        hospitalViewModel: HospitalViewModel(hospitalRepository: MockHospitalRepository(), locationProvider: MockLocationProvider()),
        musterViewModel: MusterViewModel(musterRepository: MockMusterRepository())
    )
    .environmentObject(AppStateManager.shared)
    .environmentObject(AppStorageManager())
}
