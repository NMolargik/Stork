//
//  UserDeliveryDistributionView.swift
//  skipapp-stork
//
//  Created by Nick Molargik on 1/2/25.
//

import SwiftUI
import StorkModel

struct UserDeliveryDistributionView: View {
    @Environment(\.colorScheme) var colorScheme

    // MARK: - Input Data
    let profiles: [Profile]
    let deliveries: [Delivery]

    @StateObject private var colorsViewModel = UserColorsViewModel()

    private var sixMonthsAgo: Date {
        Calendar.current.date(byAdding: .month, value: -6, to: Date()) ?? Date()
    }

    init(profiles: [Profile], deliveries: [Delivery]) {
        self.profiles = profiles
        self.deliveries = deliveries
    }

    // MARK: - Body
    var body: some View {
        VStack(spacing: 10) {
            userListView

            distributionBarView
                .frame(height: 24)
                .cornerRadius(20)
        }
        .padding()
        .onAppear {
            colorsViewModel.generateUserColors(for: profiles)
        }
        .onChange(of: profiles) { newProfiles in
            colorsViewModel.generateUserColors(for: newProfiles)
        }
    }

    // MARK: - Subviews

    private var userListView: some View {
        let sortedProfiles = sortedProfilesByDeliveryCount()

        return ScrollView(.horizontal) {
            HStack(alignment: .center, spacing: 16) {
                // Profiles
                ForEach(sortedProfiles, id: \.id) { profile in
                    HStack(spacing: 8) {
                        Circle()
                            .fill(colorsViewModel.userColors[profile.id] ?? .gray)
                            .frame(width: 12, height: 12)
                            .padding(1)
                            .background(Circle().foregroundStyle(.white))

                        Text(profile.initials)
                            .foregroundStyle(colorScheme == .dark ? .black : .white)
                            .font(.body)
                            .fontWeight(.bold)
                    }
                    .padding(.horizontal, 4)
                }

                // Other
                HStack(spacing: 8) {
                    Circle()
                        .fill(colorsViewModel.userColors["Old Members"] ?? .gray)
                        .frame(width: 12, height: 12)
                        .padding(1)
                        .background(Circle().foregroundStyle(.white))

                    Text("Old Members")
                        .foregroundStyle(colorScheme == .dark ? .black : .white)
                        .font(.body)
                        .fontWeight(.bold)
                }
                .padding(.horizontal, 4)
            }
            .padding(4)
            .background(Rectangle()
                .foregroundStyle(colorScheme == .dark ? .white : .black)
                .cornerRadius(10)
                .shadow(radius: 2))
            .padding(.vertical, 4)
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
            if let userId = profiles.first(where: { $0.id == delivery.userId })?.id {
                counts[userId, default: 0] += 1
            } else {
                counts["Old Members", default: 0] += 1
            }
        }
        
        return counts
    }

    private func sortedProfilesByDeliveryCount() -> [Profile] {
        let userDeliveryCounts = userDeliveryCounts()
        return profiles.sorted {
            let countA = userDeliveryCounts[$0.id] ?? 0
            let countB = userDeliveryCounts[$1.id] ?? 0
            return countA > countB
        }
    }
}
