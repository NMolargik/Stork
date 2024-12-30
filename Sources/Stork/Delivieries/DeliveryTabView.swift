//
//  DeliveryTabView.swift
//
//
//  Created by Nick Molargik on 11/30/24.
//

import SwiftUI
import StorkModel

@MainActor
struct DeliveryTabView: View {
    @AppStorage("errorMessage") var errorMessage: String = ""
    @AppStorage("leftHanded") var leftHanded: Bool = false
    
    @EnvironmentObject var deliveryViewModel: DeliveryViewModel
    @EnvironmentObject var profileViewModel: ProfileViewModel
    
    @Binding var showingDeliveryAddition: Bool
    
    // Single untyped path for all main flow navigation
    @State private var navigationPath = NavigationPath()
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            DeliveryListView(showingDeliveryAddition: $showingDeliveryAddition)
                .refreshable {
                    Task {
                        do {
                            try await deliveryViewModel.getUserDeliveries(profile: profileViewModel.profile)
                        } catch {
                            errorMessage = error.localizedDescription
                            throw error
                        }
                    }
                }
                .navigationTitle("Deliveries")
                // Matches NavigationLink(value: delivery) calls in DeliveryListView
                .navigationDestination(for: Delivery.self) { delivery in
                    if let index = deliveryViewModel.deliveries.firstIndex(where: { $0.id == delivery.id }) {
                        DeliveryDetailView(delivery: $deliveryViewModel.deliveries[index])
                    } else {
                        Text("Delivery not found")
                    }
                }
                .toolbar {
                    ToolbarItem {
                        Button(action: {
                            withAnimation {
                                self.showingDeliveryAddition = true
                            }
                        }, label: {
                            Text("New Delivery")
                                .foregroundStyle(.orange)
                                .fontWeight(.bold)
                        })
                    }
                }
            
            Spacer()
        }
        // Present DeliveryAdditionView via sheet when showingDeliveryAddition is flipped
        .sheet(isPresented: $showingDeliveryAddition) {
            NavigationStack {
                DeliveryAdditionView(showingDeliveryAddition: $showingDeliveryAddition)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Text("New Delivery")
                                .fontWeight(.bold)

                        }
                        
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button(action: {
                                withAnimation {
                                    showingDeliveryAddition = false
                                }
                            }) {
                                Text("Cancel")
                                    .foregroundStyle(.orange)
                            }
                        }
                    }
            }
            .interactiveDismissDisabled()
        }
    }
}

#Preview {
    DeliveryTabView(showingDeliveryAddition: .constant(false))
        .environmentObject(DeliveryViewModel(deliveryRepository: MockDeliveryRepository()))
        .environmentObject(ProfileViewModel(profileRepository: MockProfileRepository()))
}
