//
//  MusterTabView.swift
//
//
//  Created by Nick Molargik on 11/29/24.
//

import SwiftUI
import StorkModel

struct MusterTabView: View {
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("errorMessage") var errorMessage: String = ""

    @EnvironmentObject var profileViewModel: ProfileViewModel
    @EnvironmentObject var musterViewModel: MusterViewModel
    @EnvironmentObject var deliveryViewModel: DeliveryViewModel
    
    @Binding var showingDeliveryAddition: Bool
    @Binding var selectedTab: Tab
    
    @State private var showingMusterInvitations: Bool = false
    @State private var navigationPath = NavigationPath()
    @State private var showLeaveMusterSheet = false
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            if let muster = musterViewModel.currentMuster {
                VStack(spacing: 0) {
                    HStack (spacing: 20) {
                        Spacer()
                        
                        Menu {
                            if musterViewModel.isUserAdmin(profile: profileViewModel.profile) {
                                
                                Button {
                                    musterViewModel.showInviteUserSheet = true
                                } label: {
                                    Label("Invite User", systemImage: "person.badge.plus")
                                }
                                
                                Button {
                                    musterViewModel.showAssignAdminSheet = true
                                } label: {
                                    Label("Assign Admin", systemImage: "person.badge.shield.exclamationmark.fill")
                                }
                                
                                Button {
                                    musterViewModel.showRenameSheet = true
                                } label: {
                                    Label("Rename Muster", systemImage: "tag.fill")
                                }
                            }
                            
                            Button {
                                showLeaveMusterSheet = true
                            } label: {
                                Label("Leave Muster", systemImage: "door.left.hand.open")
                            }
                            
                        } label: {
                            Image("gear")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 24, height: 24)
                                .foregroundStyle(Color("storkOrange"))
                        }

                        Button {
                            Task {
                                try await musterViewModel.loadCurrentMuster(profileViewModel: profileViewModel, deliveryViewModel: deliveryViewModel)
                            }
                        } label: {
                            Image("arrow.2.squarepath")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 24, height: 24)
                                .fontWeight(.bold)
                                .foregroundStyle(.green)
                        }
                        
                        Button {
                            withAnimation {
                                triggerHaptic()
                                deliveryViewModel.startNewDelivery()
                                showingDeliveryAddition = true
                                selectedTab = .deliveries
                            }
                        } label: {
                            Image("plus")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 24, height: 24)
                                .foregroundStyle(Color("storkIndigo"))
                        }
                    }
                    .padding()
                    
                    HStack {
                        Text(muster.name)
                            .font(.title2).fontWeight(.bold)
                        
                        Spacer()
                    }
                    .padding(.leading)
                    
                    UserDeliveryDistributionView(deliveries: deliveryViewModel.musterDeliveries)
                    
                    ZStack {
                        JarView(
                            deliveries: Binding(get: { deliveryViewModel.musterDeliveries }, set: { deliveryViewModel.musterDeliveries = $0 ?? [] }),
                            headerText: getCurrentWeekRange() ?? "",
                            isTestMode: false, isMusterTest: false
                        )

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
                    .padding()
                    
                    MusterCarouselView()
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                }
                .sheet(isPresented: $musterViewModel.showInviteUserSheet) {
                    MusterAdminInviteUserView()
                        .presentationDetents([.fraction(0.5)])
                        .interactiveDismissDisabled(true)
                }
                .sheet(isPresented: $musterViewModel.showAssignAdminSheet) {
                    MusterAdminAssignAdminView()
                        .presentationDetents([.medium])
                        .interactiveDismissDisabled(true)
                }
                .sheet(isPresented: $musterViewModel.showRenameSheet) {
                    MusterAdminRenameView()
                        .presentationDetents([.fraction(0.45)])
                        .interactiveDismissDisabled(true)
                }
            } else {
                MusterSplashView()
            }
        }
        .sheet(isPresented: $showLeaveMusterSheet) {
            VStack(spacing: 20) {
                Text("Leave Muster?")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)

                Text("Are you sure you want to leave this muster? This action cannot be undone.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)

                HStack {
                    CustomButtonView(text: "Cancel", width: 150, height: 50, color: Color("storkOrange"), isEnabled: true, onTapAction: {
                        showLeaveMusterSheet = false

                    })
                    .padding(.horizontal, 5)
                    
                    CustomButtonView(text: "Leave", width: 150, height: 50, color: Color.red, isEnabled: true, onTapAction: {
                        showLeaveMusterSheet = false
                        leaveMuster()
                    })
                    .padding(.horizontal, 5)

                }
            }
            .padding()
            .presentationDetents([.fraction(0.4)])
        }
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
        let weekDeliveries = deliveryViewModel.musterDeliveries.filter { delivery in
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
    
    private func deliveriesForCurrentWeek() -> [Delivery] {
        let calendar = Calendar.current
        let now = Date()

        // Get start and end of the current week
        guard let weekStart = calendar.dateInterval(of: .weekOfYear, for: now)?.start else {
            return []
        }
        guard let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStart) else {
            return []
        }

        // Filter deliveries within the week range
        return deliveryViewModel.musterDeliveries.filter { delivery in
            delivery.date >= weekStart && delivery.date <= weekEnd
        }
    }
    
    private func leaveMuster() {
        Task {
            musterViewModel.isWorking = true

            do {
                try await musterViewModel.leaveMuster(profileViewModel: profileViewModel, deliveryViewModel: deliveryViewModel)
                
                profileViewModel.tempProfile = profileViewModel.profile
                profileViewModel.tempProfile.musterId = ""
                
                try await profileViewModel.updateProfile()
            } catch {
                musterViewModel.isWorking = false
                errorMessage = error.localizedDescription
                throw error
            }
            
            deliveryViewModel.musterDeliveries.removeAll()
            deliveryViewModel.groupedMusterDeliveries.removeAll()
            
            musterViewModel.isWorking = false
        }
    }
}

#Preview {
    MusterTabView(showingDeliveryAddition: .constant(false), selectedTab: .constant(.muster))
        .environmentObject(ProfileViewModel(profileRepository: MockProfileRepository()))
        .environmentObject(MusterViewModel(musterRepository: MockMusterRepository()))
}
