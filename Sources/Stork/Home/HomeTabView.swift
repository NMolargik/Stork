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
                headerSection
                
                HomeCarouselView()
                
                Spacer()
            }
            .navigationTitle("Stork")
            .toolbar { profileButton }
            .padding()
        }
        .sheet(isPresented: $showProfileView, content: {
            ProfileView()
                .interactiveDismissDisabled()
                .presentationDetents(profileViewModel.editingProfile ? [.fraction(0.75)] : [.fraction(0.3)])
        })
    }
}

// MARK: - Header Section
private extension HomeTabView {
    var headerSection: some View {
        HStack {
            ZStack {
                JarView(deliveries: Binding(get: { deliveryViewModel.deliveries }, set: { deliveryViewModel.deliveries = $0 ?? [] }),
                        headerText: currentWeekRange,
                        isTestMode: false)
                    .frame(width: 180)
                
                WeekRangeView(weekRange: currentWeekRange, colorScheme: colorScheme)
            }
            
            Spacer()
            
            VStack {
                JarSummaryView(deliveries: $deliveryViewModel.deliveries)
                
                Spacer()
                
                PlusButton {
                    withAnimation {
                        triggerHaptic()
                        deliveryViewModel.startNewDelivery()
                        showingDeliveryAddition = true
                        selectedTab = .deliveries
                    }
                }
            }
            .padding(.leading, 8)
        }
        .frame(height: 320)
    }
}

// MARK: - Computed Properties
private extension HomeTabView {
    var profileButton: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            Button {
                triggerHaptic()
                withAnimation { showProfileView = true }
            } label: {
                InitialsAvatarView(
                    firstName: profileViewModel.profile.firstName,
                    lastName: profileViewModel.profile.lastName
                )
            }
        }
    }
    
    var currentWeekRange: String {
        let calendar = Calendar.current
        let now = Date()
        
        guard let weekStart = calendar.dateInterval(of: .weekOfYear, for: now)?.start,
              let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStart) else {
            return ""
        }
        
        return "\(dateFormatter.string(from: weekStart)) - \(dateFormatter.string(from: weekEnd))"
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d" // Example: "Aug 9"
        return formatter
    }
}



// MARK: - Preview
#Preview {
    HomeTabView(navigationPath: .constant([]), selectedTab: .constant(Tab.home), showingDeliveryAddition: .constant(false))
        .environmentObject(ProfileViewModel(profileRepository: MockProfileRepository()))
        .environmentObject(DeliveryViewModel(deliveryRepository: MockDeliveryRepository()))
}
