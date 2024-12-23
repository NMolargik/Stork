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
    
    @State private var showProfileView: Bool = false
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            Group {
                Spacer()
                
                ZStack {
                    Rectangle()
                        .frame(width: 300, height: 200)
                        .foregroundStyle(.gray)
                    
                    Text("Jar and Marbles View")
                        .foregroundStyle(.black)
                }
                
                ZStack {
                    Rectangle()
                        .frame(width: 300, height: 200)
                        .foregroundStyle(.gray)
                    
                    Text("Personal Stats Graph")
                        .foregroundStyle(.black)
                }
                
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
            .sheet(isPresented: $showProfileView, content: {
                ProfileView()
                #if !SKIP
                    .interactiveDismissDisabled()
                #endif
            })
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        withAnimation {
                            showProfileView = true
                        }
                    }, label: {
                        InitialsAvatarView(firstName: profileViewModel.profile.firstName, lastName: profileViewModel.profile.lastName)
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
