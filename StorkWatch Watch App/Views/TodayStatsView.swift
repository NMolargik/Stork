//
//  TodayStatsView.swift
//  StorkWatch Watch App
//
//  Created by Nick Molargik on 1/17/26.
//

import SwiftUI
import SwiftData

struct TodayStatsView: View {
    @Environment(\.modelContext) private var modelContext

    let deliveries: [Delivery]
    let healthManager: WatchHealthManager

    @State private var isRefreshing = false

    private var todayDeliveries: [Delivery] {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())
        return deliveries.filter { calendar.isDate($0.date, inSameDayAs: startOfToday) }
    }

    private var todayBabyCount: Int {
        todayDeliveries.reduce(0) { $0 + ($1.babies?.count ?? 0) }
    }

    private var todayStats: (boys: Int, girls: Int, loss: Int) {
        var boys = 0, girls = 0, loss = 0
        for delivery in todayDeliveries {
            for baby in delivery.babies ?? [] {
                switch baby.sex {
                case .male: boys += 1
                case .female: girls += 1
                case .loss: loss += 1
                }
            }
        }
        return (boys, girls, loss)
    }

    private var weekBabyCount: Int {
        let week = currentWeekRange()
        let weekDeliveries = deliveries.filter { $0.date >= week.start && $0.date < week.end }
        return weekDeliveries.reduce(0) { $0 + ($1.babies?.count ?? 0) }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                // Today header
                HStack {
                    Image("storkicon")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)

                    Text("Today")
                        .font(.headline)
                }

                // Baby count circle
                ZStack {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 80, height: 80)

                    VStack(spacing: 2) {
                        Text("\(todayBabyCount)")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .monospacedDigit()
                        Text(todayBabyCount == 1 ? "baby" : "babies")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }

                // Sex breakdown pills
                if todayBabyCount > 0 {
                    HStack(spacing: 8) {
                        StatPill(count: todayStats.boys, label: "Boy", color: .storkBlue)
                        StatPill(count: todayStats.girls, label: "Girl", color: .storkPink)
                        if todayStats.loss > 0 {
                            StatPill(count: todayStats.loss, label: "Loss", color: .storkPurple)
                        }
                    }
                }

                // Week stats
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("This Week")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("\(weekBabyCount)")
                            .font(.title3.bold())
                            .monospacedDigit()
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Deliveries")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("\(todayDeliveries.count)")
                            .font(.title3.bold())
                            .monospacedDigit()
                    }
                }
                .padding(.horizontal, 8)
            }
            .padding()
        }
        .navigationTitle("Stork")
        .refreshable {
            await refreshData()
        }
    }

    private func refreshData() async {
        isRefreshing = true
        defer { isRefreshing = false }

        // Refresh step count from HealthKit
        healthManager.startObservingStepCount()

        // Give SwiftData/iCloud a moment to sync any pending changes
        try? await Task.sleep(nanoseconds: 500_000_000)

        // Trigger haptic feedback on completion
        WatchHaptics.success()
    }
}

// MARK: - Stat Pill
struct StatPill: View {
    let count: Int
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 2) {
            Text("\(count)")
                .font(.system(.body, design: .rounded, weight: .semibold))
                .monospacedDigit()
            Text(label)
                .font(.system(size: 9))
        }
        .foregroundStyle(color)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.2), in: Capsule())
    }
}

// MARK: - Week Range Helper
struct WeekRange {
    let start: Date
    let end: Date
}

func currentWeekRange(now: Date = Date()) -> WeekRange {
    var calendar = Calendar(identifier: .gregorian)
    calendar.firstWeekday = 1 // Sunday
    let weekday = calendar.component(.weekday, from: now)
    let start = calendar.startOfDay(for: calendar.date(byAdding: .day, value: -(weekday - 1), to: now)!)
    let end = calendar.date(byAdding: .day, value: 7, to: start)!
    return WeekRange(start: start, end: end)
}

#Preview {
    TodayStatsView(deliveries: [], healthManager: WatchHealthManager())
}
