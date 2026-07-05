//
//  PersonalBestsCard.swift
//  StorkFeatureDashboard
//

#if os(iOS)
import SwiftUI
import StorkCore
import StorkDesignSystem

struct PersonalBestsCard: View {
    let deliveries: [Delivery]

    var body: some View {
        InsightCard(title: "Personal Bests", systemImage: "trophy.fill", accent: .storkOrange) {
            let stats = DeliveryStatistics.personalBests(deliveries: deliveries)
            VStack(alignment: .leading, spacing: 12) {
                if stats.mostDeliveriesInDay != nil || stats.longestStreak > 0 {
                    if let best = stats.mostDeliveriesInDay {
                        BestRow(icon: "sun.max.fill", title: "Most in a Day", value: "\(best.count)",
                                subtitle: formatDate(best.date, style: .medium), color: .orange)
                    }
                    if let best = stats.mostDeliveriesInWeek {
                        BestRow(icon: "calendar.badge.clock", title: "Most in a Week", value: "\(best.count)",
                                subtitle: "Week of \(formatDate(best.weekStart, style: .short))", color: .blue)
                    }
                    if let best = stats.mostDeliveriesInMonth {
                        BestRow(icon: "calendar", title: "Most in a Month", value: "\(best.count)",
                                subtitle: formatDate(best.monthStart, style: .monthYear), color: .purple)
                    }
                    if let best = stats.mostBabiesInDay {
                        BestRow(icon: "figure.2.and.child.holdinghands", title: "Most Babies in a Day", value: "\(best.count)",
                                subtitle: formatDate(best.date, style: .medium), color: .pink)
                    }
                    if stats.longestStreak > 1 {
                        Divider()
                        HStack {
                            Image(systemName: "flame.fill").foregroundStyle(.orange)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Longest Streak").font(.caption).foregroundStyle(.secondary)
                                Text("\(stats.longestStreak) consecutive days").font(.subheadline.bold())
                            }
                            Spacer()
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("Longest streak: \(stats.longestStreak) consecutive days with deliveries")
                    }
                } else {
                    EmptyCardLabel()
                }
            }
        }
    }

    private struct BestRow: View {
        let icon: String
        let title: String
        let value: String
        let subtitle: String
        let color: Color

        var body: some View {
            HStack {
                Image(systemName: icon).font(.title3).foregroundStyle(color).frame(width: 30)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.caption).foregroundStyle(.secondary)
                    Text(subtitle).font(.caption2).foregroundStyle(.tertiary)
                }
                Spacer()
                Text(value).font(.title2.bold()).foregroundStyle(color)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(title): \(value), \(subtitle)")
        }
    }

    private enum DateFormatStyle { case short, medium, monthYear }

    private func formatDate(_ date: Date, style: DateFormatStyle) -> String {
        let formatter = DateFormatter()
        switch style {
        case .short: formatter.dateStyle = .short
        case .medium: formatter.dateStyle = .medium
        case .monthYear: formatter.setLocalizedDateFormatFromTemplate("MMMM yyyy")
        }
        return formatter.string(from: date)
    }
}
#endif
