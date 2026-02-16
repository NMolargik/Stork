//
//  DayOfWeekCard.swift
//  Stork
//
//  Created by Nick Molargik on 1/17/26.
//

import SwiftUI
import SwiftData

struct DayOfWeekCard: View {
    @Environment(DeliveryManager.self) private var deliveryManager: DeliveryManager
    let viewModel: DashboardView.ViewModel

    var body: some View {
        InsightCard(title: "Day of Week", systemImage: "calendar", accent: .storkPink) {
            let stats = viewModel.dayOfWeekStats(deliveries: deliveryManager.deliveries)
            VStack(alignment: .leading, spacing: 12) {
                if stats.total > 0 {
                    // Busiest day highlight
                    if let busiestDay = stats.busiestDay {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Busiest Day")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(DashboardView.ViewModel.DayOfWeekStats.fullDayNames[busiestDay])
                                    .font(.title2.bold())
                                    .foregroundStyle(.storkPink)
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 2) {
                                Text("\(stats.busiestCount)")
                                    .font(.title2.bold())
                                    .foregroundStyle(.primary)
                                Text("total deliveries on this day of the week")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("Busiest day is \(DashboardView.ViewModel.DayOfWeekStats.fullDayNames[busiestDay]) with \(stats.busiestCount) deliveries")
                    }

                    Divider()

                    // Bar chart visualization
                    HStack(alignment: .bottom, spacing: 4) {
                        ForEach(1...7, id: \.self) { weekday in
                            let count = stats.dayCounts[weekday] ?? 0
                            let maxCount = stats.busiestCount > 0 ? stats.busiestCount : 1
                            let heightRatio = CGFloat(count) / CGFloat(maxCount)

                            VStack(spacing: 4) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(weekday == stats.busiestDay ? Color.storkPink : Color.storkPink.opacity(0.4))
                                    .frame(width: 28, height: max(8, 60 * heightRatio))

                                Text(DashboardView.ViewModel.DayOfWeekStats.dayNames[weekday])
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            .accessibilityLabel("\(DashboardView.ViewModel.DayOfWeekStats.fullDayNames[weekday]): \(count) deliveries")
                        }
                    }
                    .frame(maxWidth: .infinity)
                } else {
                    Label("No deliveries logged yet.", systemImage: "tray.fill")
                        .foregroundStyle(.secondary)
                        .labelStyle(.titleOnly)
                }
            }
        }
    }
}

#Preview {
    let container: ModelContainer = {
        let schema = Schema([Delivery.self, Baby.self])
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        return try! ModelContainer(for: schema, configurations: [configuration])
    }()
    let context = ModelContext(container)

    DayOfWeekCard(viewModel: DashboardView.ViewModel())
        .environment(DeliveryManager(context: context))
}
