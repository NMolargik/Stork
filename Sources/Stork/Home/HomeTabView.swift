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
    @State private var graphTabIndex: Int = 0
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            VStack {
                
                //TODO: Jar View
                
                
                Spacer()
                
                HomeCarouselView()
                    

                Spacer()
                
                CustomButtonView(text: "Start A New Delivery", width: 250, height: 50, color: Color.indigo, isEnabled: true, onTapAction: {
                    withAnimation {
                        deliveryViewModel.startNewDelivery()

                        showingDeliveryAddition = true
                        selectedTab = .deliveries
                    }
                })
            }
            .padding(.bottom, 20)
            .navigationTitle("Stork")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        triggerHaptic()
                        
                        withAnimation {
                            showProfileView = true
                        }
                    }, label: {
                        InitialsAvatarView(firstName: profileViewModel.profile.firstName, lastName: profileViewModel.profile.lastName)
                    })
                }
            }
            .sheet(isPresented: $showProfileView, content: {
                ProfileView()
                    .interactiveDismissDisabled()
                    .presentationDetents(profileViewModel.editingProfile ? [.fraction(0.75)] : [.fraction(0.3)])
            })
        }
        .frame(maxWidth: .infinity)
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
    HomeTabView(navigationPath: .constant([]), selectedTab: .constant(Tab.home), showingDeliveryAddition: .constant(false))
        .environmentObject(ProfileViewModel(profileRepository: MockProfileRepository()))
        .environmentObject(DeliveryViewModel(deliveryRepository: MockDeliveryRepository()))
}
