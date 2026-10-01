//
//  SexDistributionCard.swift
//  StorkFeatureDashboard
//

#if os(iOS)
import SwiftUI
import Charts
import StorkCore
import StorkDesignSystem

struct SexDistributionCard: View {
    let deliveries: [Delivery]

    var body: some View {
        InsightCard(title: String(localized: "Sex Distribution", bundle: .module), systemImage: "chart.pie.fill", accent: .storkPurple) {
            let stats = DeliveryStatistics.sexDistribution(deliveries: deliveries)
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    SexPill(label: String(localized: "Male", bundle: .module), percentage: stats.malePercentage, color: .storkBlue)
                    SexPill(label: String(localized: "Female", bundle: .module), percentage: stats.femalePercentage, color: .storkPink)
                    SexPill(label: String(localized: "Loss", bundle: .module), percentage: stats.lossPercentage, color: .storkPurple)
                }
                if stats.total > 0 {
                    ZStack {
                        Chart {
                            ForEach([
                                ("Male", stats.maleCount, Color.storkBlue),
                                ("Female", stats.femaleCount, Color.storkPink),
                                ("Loss", stats.lossCount, Color.storkPurple),
                            ], id: \.0) { _, count, color in
                                SectorMark(angle: .value("Count", count), innerRadius: .ratio(0.52), angularInset: 1.0)
                                    .foregroundStyle(color)
                            }
                        }
                        .frame(height: 220)
                        .accessibilityLabel(Text("Pie chart showing sex distribution: \(stats.maleCount) male, \(stats.femaleCount) female, \(stats.lossCount) loss", bundle: .module))

                        VStack(spacing: 2) {
                            Text("Babies", bundle: .module).font(.caption).foregroundStyle(.secondary)
                            AnimatedInteger(value: stats.total, font: .title2, fontWeight: .bold)
                        }
                        .allowsHitTesting(false)
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel(Text("Total babies: \(stats.total)", bundle: .module))
                    }
                } else {
                    Label(String(localized: "No babies logged yet.", bundle: .module), systemImage: "tray.fill")
                        .foregroundStyle(.secondary).labelStyle(.titleOnly)
                }
            }
        }
    }

    private struct SexPill: View {
        let label: String
        let percentage: Double
        let color: Color

        var body: some View {
            HStack(spacing: 6) {
                Image(systemName: "circle.fill").accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 0) {
                    Text(label).font(.caption2).foregroundStyle(.secondary)
                    HStack(spacing: 0) {
                        AnimatedNumber(value: percentage, format: "%.0f", font: .subheadline, fontWeight: .semibold, color: color)
                        Text("%", bundle: .module).font(.subheadline).fontWeight(.semibold)
                    }
                }
            }
            .padding(.horizontal, 10).padding(.vertical, 6)
            .background(.ultraThinMaterial, in: Capsule())
            .foregroundStyle(color)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(label): \(String(format: "%.0f", percentage)) percent")
        }
    }
}
#endif
