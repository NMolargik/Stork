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
                                triggerHaptic()
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
                                triggerHaptic()
                                
                                withAnimation {
                                    showingDeliveryAddition = false
                                }
                            }) {
                                Text("Cancel")
                                    .fontWeight(.bold)
                                    .foregroundStyle(.red)
                            }
                        }
                    }
            }
            .interactiveDismissDisabled()
        }
    }
    
    private func triggerHaptic() {
        #if !SKIP
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()
        #endif
    }
}

#Preview {
    DeliveryTabView(showingDeliveryAddition: .constant(false))
        .environmentObject(DeliveryViewModel(deliveryRepository: MockDeliveryRepository()))
        .environmentObject(ProfileViewModel(profileRepository: MockProfileRepository()))
}
