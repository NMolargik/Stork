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
    
    @State private var showingMusterInvitations: Bool = false
    @State private var navigationPath = NavigationPath()
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            if let muster = musterViewModel.currentMuster {
                VStack(spacing: 0) {
                    ScrollView(.horizontal) {
                        HStack(spacing: 16) {
                            ForEach(musterViewModel.musterMembers, id: \.id) { member in
                                HStack(alignment: .center) {
                                    if muster.administratorProfileIds.contains(member.id) {
                                        Image(systemName: "crown.fill")
                                            .foregroundColor(.yellow)
                                    }
                                    
                                    Text("\(member.firstName) \(member.lastName.first.map { "\($0)." } ?? "")")
                                        .fontWeight(.bold)

                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(20)
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.leading, -5)
                    .frame(height: 30)
                    
                    ZStack {
                        JarView(
                            deliveries: Binding(get: { deliveryViewModel.musterDeliveries }, set: { deliveryViewModel.musterDeliveries = $0 ?? [] }),
                            headerText: getCurrentWeekRange() ?? "",
                            isTestMode: false
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
                    
                    UserDeliveryDistributionView(profiles: musterViewModel.musterMembers, deliveries: deliveryViewModel.musterDeliveries)
                }

                .navigationTitle(muster.name)
                .confirmationDialog(
                    "Are you sure you want to leave this muster?",
                    isPresented: $musterViewModel.showLeaveConfirmation,
                    titleVisibility: .visible
                ) {
                    Button("Leave", role: .destructive) {
                        leaveMuster()
                    }
                    Button("Cancel", role: .cancel) {}
                }
                // Admin sheets
                .sheet(isPresented: $musterViewModel.showInviteUserSheet) {
                    MusterAdminInviteUserView()
                        .interactiveDismissDisabled(true)
                }
                .sheet(isPresented: $musterViewModel.showAssignAdminSheet) {
                    MusterAdminAssignAdminView()
                        .presentationDetents([.medium])
                        .interactiveDismissDisabled(true)

                }
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            Task {
                                try await musterViewModel.loadCurrentMuster(profileViewModel: profileViewModel, deliveryViewModel: deliveryViewModel)
                            }
                        } label: {
                            Label("Refresh", systemImage: "arrow.2.squarepath")
                        }
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
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
                            }
                            
                            Button {
                                leaveMuster()
                            } label: {
                                Label("Leave Muster", systemImage: "door.left.hand.open")
                            }
                            
                        } label: {
                            Image(systemName: "gear")
                                .foregroundStyle(.orange)
                                .fontWeight(.bold)
                        }
                    }
                }
            } else {
                MusterSplashView()
            }
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
            
            musterViewModel.isWorking = false
        }
    }
}

#Preview {
    MusterTabView()
        .environmentObject(ProfileViewModel(profileRepository: MockProfileRepository()))
        .environmentObject(MusterViewModel(musterRepository: MockMusterRepository()))
}
