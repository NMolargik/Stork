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
    
    /// All users in the muster (following `Profile` model).
    let profiles: [Profile]
    
    /// All deliveries to consider (for instance, from `groupedMusterDeliveries`).
    let deliveries: [Delivery]
    
    // A dictionary to store a stable random color for each user
    @State private var userColors: [String: Color] = [:]

    // Date 6 months ago to filter recent deliveries
    private var sixMonthsAgo: Date {
        Calendar.current.date(byAdding: .month, value: -6, to: Date()) ?? Date()
    }
    
    // MARK: - Body
    var body: some View {
        VStack(spacing: 10) {
            userListView
            
            distributionBarView
                .frame(height: 24)
                .cornerRadius(20)
//                .overlay(
//                    RoundedRectangle(cornerRadius: 12)
//                        .stroke(Color.primary.opacity(0.3), lineWidth: 1)
//                )
        }
        .padding()
        .onAppear {
            // Generate user colors if not already set
            assignRandomColorsIfNeeded()
        }
    }
    
    // MARK: - Subviews

    /// Displays a HORIZONTAL list of each user's initials + random-colored dot,
    /// sorted by who contributed the most deliveries to the least (over last 6 months).
    private var userListView: some View {
        // 1) Filter deliveries to the last 6 months
        let recentDeliveries = deliveries.filter { $0.date >= sixMonthsAgo }
        
        // 2) Calculate how many deliveries each user contributed
        let userDeliveryCounts = recentDeliveries.reduce(into: [String: Int]()) { dict, delivery in
            dict[delivery.userId, default: 0] += 1
        }
        
        // 3) Sort profiles by descending delivery count
        let sortedProfiles = profiles.sorted {
            let countA = userDeliveryCounts[$0.id] ?? 0
            let countB = userDeliveryCounts[$1.id] ?? 0
            return countA > countB  // Descending order
        }
        
        // 4) Wrap the initials + dots in a horizontal scroll view
        return ScrollView(Axis.Set.horizontal) {
            HStack(alignment: .center, spacing: 16) {
                ForEach(sortedProfiles, id: \.id) { profile in
                    HStack(spacing: 8) {
                        Circle()
                            .fill(userColors[profile.id] ?? .gray)
                            .frame(width: 12, height: 12)
                            .padding(1)
                            .background {
                                Circle()
                                    .foregroundStyle(.white)
                            }
                        
                        Text(profile.initials)
                            .foregroundStyle(colorScheme == .dark ? .black : .white)
                            .font(.body)
                            .fontWeight(.bold)
                    }
                    .padding(.horizontal, 4)
                }
            }
            .padding(4)
            .background {
                Rectangle()
                    .foregroundStyle(colorScheme == .dark ? .white : .black)
                    .cornerRadius(10)
                    .shadow(radius: 2)
            }
            .padding(.vertical, 4)
        }
    }
    
    /// A stacked bar (horizontal) that indicates how many deliveries each user has in last 6 months
    private var distributionBarView: some View {
        let recentDeliveries = deliveries.filter { $0.date >= sixMonthsAgo }
        let userDeliveryCounts = recentDeliveries.reduce(into: [String: Int]()) { dict, delivery in
            dict[delivery.userId, default: 0] += 1
        }
        let total = userDeliveryCounts.values.reduce(0, +)
        
        return GeometryReader { geo in
            HStack(spacing: 0) {
                ForEach(profiles, id: \.id) { profile in
                    let count = userDeliveryCounts[profile.id] ?? 0
                    let fraction = total == 0 ? 0 : CGFloat(count) / CGFloat(total)
                    
                    Rectangle()
                        .fill(userColors[profile.id] ?? .gray)
                        .frame(width: geo.size.width * Double(fraction))
                }
            }
        }
    }
    
    // MARK: - Helpers
    
    /// Assign a stable random color per user if not already set
    private func assignRandomColorsIfNeeded() {
        var temp = userColors
        for user in profiles {
            if temp[user.id] == nil {
                temp[user.id] = randomColor()
            }
        }
        userColors = temp
    }
    
    /// Return a random color using random RGB values
    private func randomColor() -> Color {
        let red = Double.random(in: 0.0...1.0)
        let green = Double.random(in: 0.0...1.0)
        let blue = Double.random(in: 0.0...1.0)
        return Color(red: red, green: green, blue: blue)
    }
}
