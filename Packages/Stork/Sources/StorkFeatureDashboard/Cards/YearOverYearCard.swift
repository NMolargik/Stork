//
//  YearOverYearCard.swift
//  StorkFeatureDashboard
//

#if os(iOS)
import SwiftUI
import StorkCore
import StorkDesignSystem

struct YearOverYearCard: View {
    let deliveries: [Delivery]

    var body: some View {
        InsightCard(title: String(localized: "Year over Year", bundle: .module), systemImage: "chart.line.uptrend.xyaxis", accent: .storkBlue) {
            let stats = DeliveryStatistics.yearOverYearStats(deliveries: deliveries)
            VStack(alignment: .leading, spacing: 12) {
                if stats.currentYearDeliveries > 0 || stats.previousYearDeliveries > 0 {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(stats.currentYear)", bundle: .module).font(.caption).foregroundStyle(.secondary)
                            HStack(alignment: .firstTextBaseline, spacing: 4) {
                                Text("\(stats.currentYearDeliveries)", bundle: .module).font(.title.bold()).foregroundStyle(.storkBlue)
                                Text("deliveries", bundle: .module).font(.caption).foregroundStyle(.secondary)
                            }
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("\(stats.currentYearBabies)", bundle: .module).font(.title2.bold()).foregroundStyle(.storkPink)
                            Text("babies", bundle: .module).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel(Text("\(stats.currentYear): \(stats.currentYearDeliveries) deliveries, \(stats.currentYearBabies) babies", bundle: .module))

                    if stats.previousYearDeliveries > 0 {
                        Divider()
                        HStack(spacing: 16) {
                            if let growth = stats.deliveryGrowth { GrowthIndicator(label: String(localized: "Deliveries", bundle: .module), growth: growth) }
                            if let growth = stats.babyGrowth { GrowthIndicator(label: String(localized: "Babies", bundle: .module), growth: growth) }
                        }
                        Text("vs \(stats.currentYear - 1): \(stats.previousYearDeliveries) deliveries, \(stats.previousYearBabies) babies", bundle: .module)
                            .font(.caption).foregroundStyle(.tertiary)
                    }

                    if stats.yearlyData.count > 2 {
                        Divider()
                        VStack(alignment: .leading, spacing: 6) {
                            Text("History", bundle: .module).font(.caption.weight(.semibold)).foregroundStyle(.secondary)
                            ForEach(stats.yearlyData.dropFirst().prefix(3), id: \.year) { yearData in
                                HStack {
                                    Text("\(yearData.year)", bundle: .module).font(.caption).foregroundStyle(.secondary).frame(width: 50, alignment: .leading)
                                    Text("\(yearData.deliveries) deliveries", bundle: .module).font(.caption)
                                    Spacer()
                                    Text("\(yearData.babies) babies", bundle: .module).font(.caption).foregroundStyle(.secondary)
                                }
                                .accessibilityElement(children: .combine)
                                .accessibilityLabel(Text("\(yearData.year): \(yearData.deliveries) deliveries, \(yearData.babies) babies", bundle: .module))
                            }
                        }
                    }
                } else {
                    EmptyCardLabel()
                }
            }
        }
    }

    private struct GrowthIndicator: View {
        let label: String
        let growth: Double

        var body: some View {
            let isPositive = growth >= 0
            HStack(spacing: 4) {
                Image(systemName: isPositive ? "arrow.up.right" : "arrow.down.right")
                    .font(.caption.bold()).foregroundStyle(isPositive ? .green : .red)
                Text(String(format: "%.1f%%", abs(growth))).font(.caption.bold()).foregroundStyle(isPositive ? .green : .red)
                Text(label).font(.caption).foregroundStyle(.secondary)
            }
            .padding(.horizontal, 8).padding(.vertical, 4)
            .background(.ultraThinMaterial, in: Capsule())
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(label) \(isPositive ? "up" : "down") \(String(format: "%.1f", abs(growth))) percent")
        }
    }
}
#endif
