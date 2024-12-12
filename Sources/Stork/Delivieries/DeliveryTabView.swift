//
//  DeliveryTabView.swift
//
//
//  Created by Nick Molargik on 11/30/24.
//

import SwiftUI
import StorkModel

struct DeliveryTabView: View {
    @AppStorage("leftHanded") var leftHanded: Bool = false
    @EnvironmentObject var deliveryViewModel: DeliveryViewModel
    @EnvironmentObject var profileViewModel: ProfileViewModel
    
    @Binding var showingDeliveryAddition: Bool
    @State private var inDetailView: Bool = false
    @State private var navigationPath: [String] = []
    
    var body: some View {
        VStack {
            if (showingDeliveryAddition) {
                NavigationStack {
                    DeliveryAdditionView(showingDeliveryAddition: $showingDeliveryAddition)
                        .toolbar {
                            ToolbarItem {
                                Button(action: {
                                    withAnimation {
                                        deliveryViewModel.resetDelivery()
                                        showingDeliveryAddition = false
                                    }
                                }, label: {
                                    Text("Cancel")
                                        .foregroundStyle(.red)

                                })
                            }
                        }
                        .navigationTitle("New Delivery")
                }
            } else {
                ZStack {
                    NavigationStack(path: $navigationPath) {
                        List {
                            DeliveryListView(showingDeliveryAddition: $showingDeliveryAddition)
                                .padding(.bottom, 70)
                        }     
                        .refreshable {
                            Task {
                                try await deliveryViewModel.deliveryRepository.listDeliveries(userId: profileViewModel.profile.id, userFirstName: nil, hospitalId: nil, musterId: nil, date: nil, babyCount: nil, deliveryMethod: nil, epiduralUsed: nil)
                            }
                        }
                        .navigationTitle("Deliveries")

                    }
                    .padding(.bottom, -50)
                    

                }
            }
        }
    }
}

#Preview {
    DeliveryTabView(showingDeliveryAddition: .constant(false))
        .environmentObject(DeliveryViewModel(deliveryRepository: MockDeliveryRepository()))
        .environmentObject(ProfileViewModel(profileRepository: MockProfileRepository()))
}
