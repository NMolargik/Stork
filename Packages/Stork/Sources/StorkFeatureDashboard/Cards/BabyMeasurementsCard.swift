//
//  BabyMeasurementsCard.swift
//  StorkFeatureDashboard
//

#if os(iOS)
import SwiftUI
import StorkCore
import StorkDesignSystem

struct BabyMeasurementsCard: View {
    @AppStorage(AppStorageKeys.useMetricUnits) private var useMetricUnits: Bool = false
    let deliveries: [Delivery]

    var body: some View {
        InsightCard(title: "Baby Measurements", systemImage: "ruler", accent: .storkOrange) {
            let stats = DeliveryStatistics.babyMeasurementStats(deliveries: deliveries)
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    Chip(icon: "scalemass.fill", caption: "Avg Weight",
                         value: UnitConversion.weightDisplay(stats.averageWeight, useMetric: useMetricUnits))
                    Chip(icon: "ruler.fill", caption: "Avg Height",
                         value: UnitConversion.heightDisplay(stats.averageHeight, useMetric: useMetricUnits))
                }
                if stats.count == 0 {
                    Label("No babies logged yet.", systemImage: "tray.fill")
                        .foregroundStyle(.secondary).labelStyle(.titleOnly)
                }
            }
        }
    }

    private struct Chip: View {
        let icon: String
        let caption: String
        let value: String

        var body: some View {
            HStack(spacing: 6) {
                Image(systemName: icon).accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 0) {
                    Text(caption).font(.caption2)
                    Text(value).font(.subheadline).fontWeight(.semibold)
                }
            }
            .padding(.horizontal, 10).padding(.vertical, 6)
            .background(.ultraThinMaterial, in: Capsule())
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(caption): \(value)")
        }
    }
}
#endif
