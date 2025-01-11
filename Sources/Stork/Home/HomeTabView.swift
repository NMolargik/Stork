//
//  HomeTabView.swift
//
//
//  Created by Nick Molargik on 11/30/24.
//

import SwiftUI
import StorkModel

struct HomeTabView: View {
    @Environment(\.colorScheme) var colorScheme
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
                HStack {
                    ZStack {
                        JarView(
                            deliveries: $deliveryViewModel.deliveries,
                            headerText: getCurrentWeekRange() ?? ""
                        )
                        .frame(width: 180)

                        VStack {
                            if let weekRange = getCurrentWeekRange() {
                                Text(weekRange)
                                    .padding(8)
                                    .foregroundStyle(.gray)
                                    .font(.headline)
                                    .fontWeight(.bold)
                                    .background {
                                        Rectangle()
                                            .foregroundStyle(colorScheme == .dark ? .black : .white)
                                            .cornerRadius(20)
                                            .shadow(color: colorScheme == .dark ? .white : .black, radius: 2)
                                    }
                                    .padding(.top, 20)
                            }
                            
                            Spacer()
                        }
                    }
                    
                    Spacer()
                    
                    VStack {
                        YourJarView(deliveries: $deliveryViewModel.deliveries)
                        
                        Spacer()
                        
                        Button(action: {
                            withAnimation {
                                triggerHaptic()
                                deliveryViewModel.startNewDelivery()

                                showingDeliveryAddition = true
                                selectedTab = .deliveries
                            }
                        }, label: {
                            Image(systemName: "plus")
                                .foregroundStyle(.white)
                                .font(.title)
                                .fontWeight(.bold)
                                .padding(.vertical, 20)
                                .frame(maxWidth: .infinity)
                                .background {
                                    Rectangle()
                                        .cornerRadius(20)
                                        .foregroundStyle(.indigo)
                                        .shadow(radius: 2)
                                }
                        })
                    }
                    .padding(.leading, 8)
                }
                .padding()
                .frame(height: 320)

                HomeCarouselView()
                
                Spacer()
                
            }

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
        }
        .sheet(isPresented: $showProfileView, content: {
            ProfileView()
                .interactiveDismissDisabled()
                .presentationDetents(profileViewModel.editingProfile ? [.fraction(0.75)] : [.fraction(0.3)])
        })
    }
    
    private func triggerHaptic() {
        #if !SKIP
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()
        #endif
    }
    
    private func getCurrentWeekRange() -> String? {
        let calendar = Calendar.current
        let now = Date()

        // Get start and end of the current week
        guard let weekStart = calendar.dateInterval(of: .weekOfYear, for: now)?.start else {
            return nil
        }
        guard let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStart) else {
            return nil
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d" // Example: "Aug 9"

        let startDate = formatter.string(from: weekStart)
        let endDate = formatter.string(from: weekEnd)

        return "\(startDate) - \(endDate)"
    }
}

#Preview {
    HomeTabView(navigationPath: .constant([]), selectedTab: .constant(Tab.home), showingDeliveryAddition: .constant(false))
        .environmentObject(ProfileViewModel(profileRepository: MockProfileRepository()))
        .environmentObject(DeliveryViewModel(deliveryRepository: MockDeliveryRepository()))
}
