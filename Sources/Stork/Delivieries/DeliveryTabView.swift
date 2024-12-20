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
    @State private var inDetailView: Bool = false
    @State private var navigationPath: [String] = []
    
    var body: some View {
        VStack {
            if (showingDeliveryAddition) {
                NavigationStack {
                    DeliveryAdditionView(showingDeliveryAddition: $showingDeliveryAddition)
                        .toolbar(content: {
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button(action: {
                                    withAnimation {
                                        showingDeliveryAddition = false
                                    }
                                }) {
                                    Text("Cancel")
                                        .foregroundStyle(.red)
                                }
                            }
                        })
                }
            } else {
                ZStack {
                    NavigationStack(path: $navigationPath) {
                        List {
                            DeliveryListView(showingDeliveryAddition: $showingDeliveryAddition)
                                .padding(.bottom, 70)
                        }     
                        .refreshable {
                            Task { @MainActor in
                                do {
                                    try await deliveryViewModel.getUserDeliveries(profile: profileViewModel.profile)
                                } catch {
                                    errorMessage = error.localizedDescription
                                    throw error
                                }
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
