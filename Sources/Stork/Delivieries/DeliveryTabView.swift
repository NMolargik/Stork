//
//  DeliveryTabView.swift
//
//  Created by Nick Molargik on 11/30/24.
//

import SwiftUI
import StorkModel

@MainActor
struct DeliveryTabView: View {
    // MARK: - AppStorage
    @AppStorage("errorMessage") var errorMessage: String = ""
    @AppStorage("leftHanded") var leftHanded: Bool = false

    // MARK: - Environment Objects
    @EnvironmentObject var deliveryViewModel: DeliveryViewModel
    @EnvironmentObject var profileViewModel: ProfileViewModel

    // MARK: - Binding
    @Binding var showingDeliveryAddition: Bool

    // MARK: - State
    @State private var navigationPath = NavigationPath()

    var body: some View {
        NavigationStack(path: $navigationPath) {
            DeliveryListView(showingDeliveryAddition: $showingDeliveryAddition)
                .refreshable {
                    await refreshDeliveries()
                }
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
                        Button(action: {
                            withAnimation {
                                triggerHaptic()
                                showingDeliveryAddition = true
                            }
                        }) {
                            Text("New Delivery")
                                .foregroundStyle(Color("storkOrange"))
                                .fontWeight(.bold)
                        }
                    }
                    
                    if deliveryViewModel.hasMorePages {
                        ToolbarItem(placement: .topBarLeading) {
                            Button(action: {
                                withAnimation {
                                    loadMoreDeliveries()
                                }
                            }, label: {
                                Text("Load 6 More Months")
                                    .fontWeight(.bold)
                                    .foregroundStyle(Color("storkIndigo"))
                            })
                        }
                    }
                }
                .sheet(isPresented: $showingDeliveryAddition) {
                    DeliveryAdditionSheet(showingDeliveryAddition: $showingDeliveryAddition)
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
            errorMessage = "Failed to refresh deliveries: \(error.localizedDescription)"
        }
    }
                                                              
   // MARK: - Load More Deliveries
    private func loadMoreDeliveries() {
        Task {
            do {
                let initialCount = deliveryViewModel.deliveries.count // Track before fetch
                try await deliveryViewModel.fetchNextDeliveries(profile: profileViewModel.profile)

                // Animate only if new items were added
                let newCount = deliveryViewModel.deliveries.count
                if newCount > initialCount {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        deliveryViewModel.groupDeliveries() // Ensure UI updates smoothly
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
    DeliveryTabView(showingDeliveryAddition: .constant(false))
        .environmentObject(DeliveryViewModel(deliveryRepository: MockDeliveryRepository()))
        .environmentObject(ProfileViewModel(profileRepository: MockProfileRepository()))
}
