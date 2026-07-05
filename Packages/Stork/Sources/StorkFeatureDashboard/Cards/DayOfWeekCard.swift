//
//  DayOfWeekCard.swift
//  StorkFeatureDashboard
//

#if os(iOS)
import SwiftUI
import StorkCore
import StorkDesignSystem

struct DayOfWeekCard: View {
    let deliveries: [Delivery]

    private typealias Days = DeliveryStatistics.DayOfWeekStats

    var body: some View {
        InsightCard(title: "Day of Week", systemImage: "calendar", accent: .storkPink) {
            let stats = DeliveryStatistics.dayOfWeekStats(deliveries: deliveries)
            VStack(alignment: .leading, spacing: 12) {
                if stats.total > 0 {
                    if let busiestDay = stats.busiestDay {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Busiest Day").font(.caption).foregroundStyle(.secondary)
                                Text(Days.fullDayNames[busiestDay]).font(.title2.bold()).foregroundStyle(.storkPink)
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 2) {
                                Text("\(stats.busiestCount)").font(.title2.bold())
                                Text("total deliveries on this day of the week").font(.caption).foregroundStyle(.secondary)
                            }
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("Busiest day is \(Days.fullDayNames[busiestDay]) with \(stats.busiestCount) deliveries")
                    }

                    Divider()

                    HStack(alignment: .bottom, spacing: 4) {
                        ForEach(1...7, id: \.self) { weekday in
                            let count = stats.dayCounts[weekday] ?? 0
                            let maxCount = stats.busiestCount > 0 ? stats.busiestCount : 1
                            let ratio = CGFloat(count) / CGFloat(maxCount)
                            VStack(spacing: 4) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(weekday == stats.busiestDay ? Color.storkPink : Color.storkPink.opacity(0.4))
                                    .frame(width: 28, height: max(8, 60 * ratio))
                                Text(Days.dayNames[weekday]).font(.caption2).foregroundStyle(.secondary)
                            }
                            .accessibilityElement(children: .combine)
                            .accessibilityLabel("\(Days.fullDayNames[weekday]): \(count) deliveries")
                        }
                    }
                    .frame(maxWidth: .infinity)
                } else {
                    EmptyCardLabel()
                }
            }
        }
    }
}
#endif
