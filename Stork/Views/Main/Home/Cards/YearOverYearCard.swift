//
//  YearOverYearCard.swift
//  Stork
//
//  Created by Nick Molargik on 1/17/26.
//

import SwiftUI
import SwiftData

struct YearOverYearCard: View {
    @Environment(DeliveryManager.self) private var deliveryManager: DeliveryManager
    let viewModel: HomeView.ViewModel

    var body: some View {
        InsightCard(title: "Year over Year", systemImage: "chart.line.uptrend.xyaxis", accent: .storkBlue) {
            let stats = viewModel.yearOverYearStats(deliveries: deliveryManager.deliveries)
            VStack(alignment: .leading, spacing: 12) {
                if stats.currentYearDeliveries > 0 || stats.previousYearDeliveries > 0 {
                    // Current year stats
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(stats.currentYear)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            HStack(alignment: .firstTextBaseline, spacing: 4) {
                                Text("\(stats.currentYearDeliveries)")
                                    .font(.title.bold())
                                    .foregroundStyle(.storkBlue)
                                Text("deliveries")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("\(stats.currentYearBabies)")
                                .font(.title2.bold())
                                .foregroundStyle(.storkPink)
                            Text("babies")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(stats.currentYear): \(stats.currentYearDeliveries) deliveries, \(stats.currentYearBabies) babies")

                    // Growth indicators
                    if stats.previousYearDeliveries > 0 {
                        Divider()

                        HStack(spacing: 16) {
                            if let growth = stats.deliveryGrowth {
                                growthIndicator(label: "Deliveries", growth: growth)
                            }
                            if let growth = stats.babyGrowth {
                                growthIndicator(label: "Babies", growth: growth)
                            }
                        }

                        // Previous year comparison
                        Text("vs \(stats.currentYear - 1): \(stats.previousYearDeliveries) deliveries, \(stats.previousYearBabies) babies")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }

                    // Historical data (if multiple years)
                    if stats.yearlyData.count > 2 {
                        Divider()

                        VStack(alignment: .leading, spacing: 6) {
                            Text("History")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)

                            ForEach(stats.yearlyData.dropFirst().prefix(3), id: \.year) { yearData in
                                HStack {
                                    Text("\(yearData.year)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .frame(width: 50, alignment: .leading)
                                    Text("\(yearData.deliveries) deliveries")
                                        .font(.caption)
                                    Spacer()
                                    Text("\(yearData.babies) babies")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                } else {
                    Label("No deliveries logged yet.", systemImage: "tray.fill")
                        .foregroundStyle(.secondary)
                        .labelStyle(.titleOnly)
                }
            }
        }
    }

    private func growthIndicator(label: String, growth: Double) -> some View {
        let isPositive = growth >= 0
        return HStack(spacing: 4) {
            Image(systemName: isPositive ? "arrow.up.right" : "arrow.down.right")
                .font(.caption.bold())
                .foregroundStyle(isPositive ? .green : .red)
            Text(String(format: "%.1f%%", abs(growth)))
                .font(.caption.bold())
                .foregroundStyle(isPositive ? .green : .red)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(.ultraThinMaterial, in: Capsule())
        .accessibilityLabel("\(label) \(isPositive ? "up" : "down") \(String(format: "%.1f", abs(growth))) percent")
    }
}

#Preview {
    let container: ModelContainer = {
        let schema = Schema([Delivery.self, Baby.self])
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        return try! ModelContainer(for: schema, configurations: [configuration])
    }()
    let context = ModelContext(container)

    YearOverYearCard(viewModel: HomeView.ViewModel())
        .environment(DeliveryManager(context: context))
}
