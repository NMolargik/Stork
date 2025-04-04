//
//  MusterTabView.swift
//
//
//  Created by Nick Molargik on 11/29/24.
//

import SwiftUI
import StorkModel

struct MusterTabView: View {
    @EnvironmentObject var appStateManager: AppStateManager

    @AppStorage(StorageKeys.useDarkMode) var useDarkMode: Bool = false
    
    @ObservedObject var profileViewModel: ProfileViewModel
    @ObservedObject var musterViewModel: MusterViewModel
    @ObservedObject var deliveryViewModel: DeliveryViewModel
    @ObservedObject var hospitalViewModel: HospitalViewModel
    
    @State private var showingMusterInvitations: Bool = false
    @State private var showLeaveMusterSheet = false
    
    private var headerText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: Date())
    }
    
    var body: some View {
        NavigationStack(path: $appStateManager.navigationPath) {
            if let muster = musterViewModel.currentMuster {
                VStack(spacing: 0) {
                    HStack (spacing: 20) {
                        Spacer()
                        
                        Menu {
                            if musterViewModel.isUserAdmin(profile: profileViewModel.profile) {
                                
                                Button {
                                    musterViewModel.showInviteUserSheet = true
                                } label: {
                                    Label {
                                        Text("Invite User")
                                    } icon: {
                                        Image("person.badge.plus", bundle: .module)
                                            .resizable()
                                            .foregroundStyle(Color("storkBlue"))
                                            .frame(width: 25)
                                    }
                                }
                                
                                Button {
                                    musterViewModel.showAssignAdminSheet = true
                                } label: {
                                    Label {
                                        Text("Assign Admin")
                                    } icon: {
                                        Image("person.badge.shield.exclamationmark.fill", bundle: .module)
                                            .resizable()
                                            .foregroundStyle(.yellow)
                                            .frame(width: 25)
                                    }
                                }
                                
                                Button {
                                    musterViewModel.showRenameSheet = true
                                } label: {
                                    Label {
                                        Text("Rename Muster")
                                    } icon: {
                                        Image("tag.fill", bundle: .module)
                                            .resizable()
                                            .foregroundStyle(Color("storkIndigo"))
                                            .frame(width: 25)
                                            
                                    }
                                }
                            }
                            
                            Button {
                                showLeaveMusterSheet = true
                            } label: {
                                Label {
                                    Text("Leave Muster")
                                } icon: {
                                    Image("door.left.hand.open", bundle: .module)
                                        .resizable()
                                        .foregroundStyle(.red)
                                        .frame(width: 25)
                                }
                            }
                            
                        } label: {
                            Image("gear", bundle: .module)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 24, height: 24)
                                .foregroundStyle(Color("storkOrange"))
                        }

                        Button {
                            HapticFeedback.trigger(style: .medium)

                            Task {
                                try await musterViewModel.loadCurrentMuster(profileViewModel: profileViewModel, deliveryViewModel: deliveryViewModel)
                            }
                        } label: {
                            Image("arrow.2.squarepath", bundle: .module)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 24, height: 24)
                                .fontWeight(.bold)
                                .foregroundStyle(.green)
                        }
                        
                        Button {
                            withAnimation {
                                HapticFeedback.trigger(style: .medium)
                                deliveryViewModel.startNewDelivery()
                                appStateManager.showingDeliveryAddition = true
                                appStateManager.selectedTab = .deliveries
                            }
                        } label: {
                            Image("plus", bundle: .module)
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
                            .foregroundStyle(useDarkMode ? Color.white : Color.black)
                        
                        Spacer()
                    }
                    .padding(.leading)
                    
                    UserDeliveryDistributionView(
                        musterViewModel: musterViewModel,
                        deliveries: deliveryViewModel.musterDeliveries
                    )
                    
                    JarView(
                        deliveries: Binding(get: { deliveryViewModel.musterDeliveries }, set: { deliveryViewModel.musterDeliveries = $0 ?? [] }),
                        isMuster: true,
                        headerText: headerText,
                        isTestMode: false
                    )
                    .padding()
                    
                    MusterCarouselView(deliveryViewModel: deliveryViewModel)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                }
                .sheet(isPresented: $musterViewModel.showInviteUserSheet) {
                    MusterAdminInviteUserView(
                        musterViewModel: musterViewModel,
                        profileViewModel: profileViewModel
                    )
                        .presentationDetents([.fraction(0.5)])
                        .interactiveDismissDisabled(true)
                }
                .sheet(isPresented: $musterViewModel.showAssignAdminSheet) {
                    MusterAdminAssignAdminView(
                        musterViewModel: musterViewModel,
                        profileViewModel: profileViewModel
                    )
                        .presentationDetents([.medium])
                        .interactiveDismissDisabled(true)
                }
                .sheet(isPresented: $musterViewModel.showRenameSheet) {
                    MusterAdminRenameView(
                        musterViewModel: musterViewModel,
                        profileViewModel: profileViewModel
                    )
                        .presentationDetents([.fraction(0.45)])
                        .interactiveDismissDisabled(true)
                }
            } else {
                MusterSplashView(
                    musterViewModel: musterViewModel,
                    profileViewModel: profileViewModel,
                    deliveryViewModel: deliveryViewModel,
                    hospitalViewModel: hospitalViewModel
                )
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
                withAnimation {
                    musterViewModel.isWorking = false
                    appStateManager.errorMessage = error.localizedDescription
                }
                throw error
            }
            
            deliveryViewModel.musterDeliveries.removeAll()
            deliveryViewModel.groupedMusterDeliveries.removeAll()
            
            musterViewModel.isWorking = false
        }
    }
}

#Preview {
    MusterTabView(
        profileViewModel: ProfileViewModel(profileRepository: MockProfileRepository()),
        musterViewModel: MusterViewModel(musterRepository: MockMusterRepository()),
        deliveryViewModel: DeliveryViewModel(deliveryRepository: MockDeliveryRepository()),
        hospitalViewModel: HospitalViewModel(hospitalRepository: MockHospitalRepository(), locationProvider: MockLocationProvider())
    )
    .environmentObject(AppStateManager.shared)
}
