//
//  DeliveryTabView.swift
//
//
//  Created by Nick Molargik on 11/30/24.
//

import SwiftUI
import StorkModel

struct DeliveryTabView: View {
    @EnvironmentObject var deliveryViewModel: DeliveryViewModel
    @EnvironmentObject var profileViewModel: ProfileViewModel
    
    @Binding var showingDeliveryAddition: Bool
    @State private var navigationPath: [String] = []
    
    var body: some View {
        VStack {
            if (showingDeliveryAddition) {
                NavigationStack {
                    DeliveryAdditionView()
                        .toolbar {
                            ToolbarItem {
                                Button(action: {
                                    withAnimation {
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
                NavigationStack(path: $navigationPath) {
                    List {
                        DeliveryListView()
                            .padding(.bottom, 70)
                    }
                    .toolbar {
                        ToolbarItem {
                            Button(action: {
                                withAnimation {
                                    showingDeliveryAddition = true
                                }
                            }, label: {
                                HStack {
                                    Text("New")
                                    Image(systemName: "plus.circle.fill")
                                }
                            })
                        }
                    }
                }
                .padding(.bottom, -50)
                .navigationTitle("Deliveries")
                
            }
        }
    }
}

#Preview {
    DeliveryTabView(showingDeliveryAddition: .constant(false))
        .environmentObject(DeliveryViewModel(deliveryRepository: MockDeliveryRepository()))
        .environmentObject(ProfileViewModel(profileRepository: MockProfileRepository()))
}
