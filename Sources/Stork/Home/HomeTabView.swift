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
                HStack {
                    JarView(deliveries: $deliveryViewModel.deliveries)
                    
                    Spacer()

                    VStack(alignment: .leading, spacing: 8) {
                        // Display the current week range
                        if let weekRange = getCurrentWeekRange() {
                            Text(weekRange)
                                .font(.headline)
                        }

                        // Display boys count
                        Text("Boys: \(countBabies(of: .male))")
                            .font(.subheadline)

                        // Display girls count
                        Text("Girls: \(countBabies(of: .female))")
                            .font(.subheadline)

                        // Display loss count
                        Text("Losses: \(countBabies(of: .loss))")
                            .font(.subheadline)
                    }
                    .padding(.horizontal)
                }
                .padding() 
                
                Spacer()
                
                HomeCarouselView()

                CustomButtonView(text: "Start A New Delivery", width: 250, height: 50, color: Color.indigo, isEnabled: true, onTapAction: {
                    withAnimation {
                        deliveryViewModel.startNewDelivery()

                        showingDeliveryAddition = true
                        selectedTab = .deliveries
                    }
                })
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
    
    private func countBabies(of sex: Sex) -> Int {
        let calendar = Calendar.current
        let now = Date()

        // Get start and end of the current week
        guard let weekStart = calendar.dateInterval(of: .weekOfYear, for: now)?.start else {
            return 0
        }
        guard let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStart) else {
            return 0
        }

        // Filter deliveries for the current week
        let weekDeliveries = deliveryViewModel.deliveries.filter { delivery in
            delivery.date >= weekStart && delivery.date <= weekEnd
        }

        // Count babies of the specified sex
        return weekDeliveries.reduce(0) { count, delivery in
            count + delivery.babies.filter { $0.sex == sex }.count
        }
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
