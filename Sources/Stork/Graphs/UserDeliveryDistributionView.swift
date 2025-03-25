//
//  UserDeliveryDistributionView.swift
//  skipapp-stork
//
//  Created by Nick Molargik on 1/2/25.
//

import SwiftUI
import StorkModel

struct UserDeliveryDistributionView: View {
    @EnvironmentObject var appStorageManager: AppStorageManager
    
    @StateObject private var colorsViewModel = UserColorsViewModel()

    @ObservedObject var musterViewModel: MusterViewModel

    let deliveries: [Delivery]

    private var sixMonthsAgo: Date {
        Calendar.current.date(byAdding: .month, value: -6, to: Date()) ?? Date()
    }

    init(musterViewModel: MusterViewModel, deliveries: [Delivery]) {
        self.musterViewModel = musterViewModel
        self.deliveries = deliveries
    }

    // MARK: - Body
    var body: some View {
        VStack(spacing: 5) {
            userListView

            distributionBarView
                .frame(height: 24)
                .cornerRadius(20)
        }
        .padding(.horizontal)
        .onAppear {
            colorsViewModel.generateUserColors(for: musterViewModel.musterMembers)
        }
        .onChange(of: musterViewModel.musterMembers) { newProfiles in
            colorsViewModel.generateUserColors(for: newProfiles)
        }
    }

    private var userListView: some View {
        let sortedProfiles = sortedProfilesByDeliveryCount()

        return ScrollView(.horizontal) {
            HStack(spacing: 16) {
                ForEach(sortedProfiles, id: \.id) { profile in
                    HStack(alignment: .center) {
                        if (musterViewModel.currentMuster?.administratorProfileIds.contains(profile.id) == true) {                 
                            Image("crown.fill", bundle: .module)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 24, height: 24)
                                .foregroundStyle(.yellow)
                        }
                        
                        Text("\(profile.firstName) \(profile.lastName.first.map { "\($0)." } ?? "")")
                            .foregroundStyle(appStorageManager.useDarkMode ? Color.white : Color.black)
                        
                        Circle()
                            .fill(colorsViewModel.userColors[profile.id] ?? .gray)
                            .frame(width: 12, height: 12)
                            .padding(1)
                            .background(Circle().foregroundStyle(.white))

                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(20)
                
                }
                
                HStack(spacing: 8) {
                    Text("Old Members")
                        .font(.body)
                        .foregroundStyle(appStorageManager.useDarkMode ? Color.white : Color.black)
                    
                    Circle()
                        .fill(colorsViewModel.userColors["Old Members"] ?? .gray)
                        .frame(width: 12, height: 12)
                        .padding(1)
                        .background(Circle().foregroundStyle(.white))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.gray.opacity(0.2))
                .cornerRadius(20)
            }
            .padding(4)
        }
    }

    private var distributionBarView: some View {
        let userDeliveryCounts = userDeliveryCounts()
        let total = userDeliveryCounts.values.reduce(0, +)

        return GeometryReader { geo in
            HStack(spacing: 0) {
                ForEach(userDeliveryCounts.keys.sorted(), id: \.self) { key in
                    let count = userDeliveryCounts[key] ?? 0
                    let fraction = total == 0 ? 0.0 : CGFloat(count) / CGFloat(total)

                    Rectangle()
                        .fill(colorsViewModel.userColors[key] ?? .gray)
                        .frame(width: geo.size.width * fraction)
                }
            }
        }
    }

    // MARK: - Helpers

    private func userDeliveryCounts() -> [String: Int] {
        let recentDeliveries = deliveries.filter { $0.date >= sixMonthsAgo }
        var counts = [String: Int]()
        
        for delivery in recentDeliveries {
            if let userId = musterViewModel.musterMembers.first(where: { $0.id == delivery.userId })?.id {
                counts[userId, default: 0] += 1
            } else {
                counts["Old Members", default: 0] += 1
            }
        }
        
        return counts
    }

    private func sortedProfilesByDeliveryCount() -> [Profile] {
        let userDeliveryCounts = userDeliveryCounts()
        return musterViewModel.musterMembers.sorted {
            let countA = userDeliveryCounts[$0.id] ?? 0
            let countB = userDeliveryCounts[$1.id] ?? 0
            return countA > countB
        }
    }
}
