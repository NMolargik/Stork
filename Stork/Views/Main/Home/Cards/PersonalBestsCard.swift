//
//  PersonalBestsCard.swift
//  Stork
//
//  Created by Nick Molargik on 1/17/26.
//

import SwiftUI
import SwiftData

struct PersonalBestsCard: View {
    @Environment(DeliveryManager.self) private var deliveryManager: DeliveryManager
    let viewModel: HomeView.ViewModel

    var body: some View {
        InsightCard(title: "Personal Bests", systemImage: "trophy.fill", accent: .storkOrange) {
            let stats = viewModel.personalBests(deliveries: deliveryManager.deliveries)
            VStack(alignment: .leading, spacing: 12) {
                if stats.mostDeliveriesInDay != nil || stats.longestStreak > 0 {
                    // Most deliveries in a day
                    if let best = stats.mostDeliveriesInDay {
                        bestRow(
                            icon: "sun.max.fill",
                            title: "Most in a Day",
                            value: "\(best.count)",
                            subtitle: formatDate(best.date, style: .medium),
                            color: .orange
                        )
                    }

                    // Most deliveries in a week
                    if let best = stats.mostDeliveriesInWeek {
                        bestRow(
                            icon: "calendar.badge.clock",
                            title: "Most in a Week",
                            value: "\(best.count)",
                            subtitle: "Week of \(formatDate(best.weekStart, style: .short))",
                            color: .blue
                        )
                    }

                    // Most deliveries in a month
                    if let best = stats.mostDeliveriesInMonth {
                        bestRow(
                            icon: "calendar",
                            title: "Most in a Month",
                            value: "\(best.count)",
                            subtitle: formatDate(best.monthStart, style: .monthYear),
                            color: .purple
                        )
                    }

                    // Most babies in a day
                    if let best = stats.mostBabiesInDay {
                        bestRow(
                            icon: "figure.2.and.child.holdinghands",
                            title: "Most Babies in a Day",
                            value: "\(best.count)",
                            subtitle: formatDate(best.date, style: .medium),
                            color: .pink
                        )
                    }

                    // Longest streak
                    if stats.longestStreak > 1 {
                        Divider()
                        HStack {
                            Image(systemName: "flame.fill")
                                .foregroundStyle(.orange)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Longest Streak")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text("\(stats.longestStreak) consecutive days")
                                    .font(.subheadline.bold())
                            }
                            Spacer()
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("Longest streak: \(stats.longestStreak) consecutive days with deliveries")
                    }
                } else {
                    Label("No deliveries logged yet.", systemImage: "tray.fill")
                        .foregroundStyle(.secondary)
                        .labelStyle(.titleOnly)
                }
            }
        }
    }

    private func bestRow(icon: String, title: String, value: String, subtitle: String, color: Color) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(subtitle)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            Spacer()

            Text(value)
                .font(.title2.bold())
                .foregroundStyle(color)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value), \(subtitle)")
    }

    private func formatDate(_ date: Date, style: DateFormatStyle) -> String {
        let formatter = DateFormatter()
        switch style {
        case .short:
            formatter.dateStyle = .short
        case .medium:
            formatter.dateStyle = .medium
        case .monthYear:
            formatter.setLocalizedDateFormatFromTemplate("MMMM yyyy")
        }
        return formatter.string(from: date)
    }

    private enum DateFormatStyle {
        case short, medium, monthYear
    }
}

#Preview {
    let container: ModelContainer = {
        let schema = Schema([Delivery.self, User.self, Baby.self])
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        return try! ModelContainer(for: schema, configurations: [configuration])
    }()
    let context = ModelContext(container)

    PersonalBestsCard(viewModel: HomeView.ViewModel())
        .environment(DeliveryManager(context: context))
}
