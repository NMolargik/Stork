//
//  HomeTabView.swift
//
//
//  Created by Nick Molargik on 11/30/24.
//

import SwiftUI
import StorkModel

struct HomeTabView: View {
    @EnvironmentObject var profileViewModel: ProfileViewModel
    @EnvironmentObject var deliveryViewModel: DeliveryViewModel
    
    @Binding var navigationPath: [String]
    @Binding var selectedTab: Tab
    @Binding var showingDeliveryAddition: Bool
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            Group {
                Spacer()
                
                CustomButtonView(text: "Start A New Delivery", width: 250, height: 50, color: Color.indigo, isEnabled: .constant(true), onTapAction: {
                    withAnimation {
                        deliveryViewModel.startNewDelivery()

                        showingDeliveryAddition = true
                        selectedTab = .deliveries
                    }
                })
            }
            .padding(.bottom, 20)
            .navigationTitle("Stork")
            .navigationDestination(for: String.self) { value in
                if value == "ProfileView" {
                    ProfileView()
                } else {
                    Text("Other View: \(value)")
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        withAnimation {
                            navigationPath.append("ProfileView")
                        }
                    }, label: {
                        //TODO: fix this
//                        if let profilePicture = profileViewModel.profile.profilePicture {
//                            Image(uiImage: profilePicture)
//                                .resizable()
//                                .scaledToFill()
//                                .frame(width: 100, height: 100)
//                                .clipShape(Circle())
//                        } else {
                            Image(systemName: "person.circle")
                                .font(.title2)
                                .foregroundStyle(.orange)
                        //}
                    })
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    HomeTabView(navigationPath: .constant([]), selectedTab: .constant(Tab.home), showingDeliveryAddition: .constant(false))
        .environmentObject(ProfileViewModel(profileRepository: MockProfileRepository()))
        .environmentObject(DeliveryViewModel(deliveryRepository: MockDeliveryRepository()))
}
