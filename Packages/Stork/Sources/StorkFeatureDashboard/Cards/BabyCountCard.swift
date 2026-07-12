//
//  BabyCountCard.swift
//  StorkFeatureDashboard
//

#if os(iOS)
import SwiftUI
import Charts
import StorkCore
import StorkDesignSystem

struct BabyCountCard: View {
    @Environment(\.horizontalSizeClass) private var hSizeClass
    let deliveries: [Delivery]

    var body: some View {
        InsightCard(title: String(localized: "Babies per Delivery", bundle: .module), systemImage: "figure.2.and.child.holdinghands", accent: .storkPink) {
            let average = DeliveryStatistics.averageBabyCount(deliveries: deliveries)
            let monthlyCounts = DeliveryStatistics.monthlyBabyCounts(deliveries: deliveries)
            let allLabels = monthlyCounts.labels
            let stride = (hSizeClass == .compact && allLabels.count > 8) ? 2 : 1
            let shownLabels = allLabels.enumerated().compactMap { $0.offset % stride == 0 ? $0.element : nil }
            let totals = DeliveryStatistics.totals(deliveries: deliveries)

            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Average", bundle: .module).font(.caption).foregroundStyle(.secondary)
                    AnimatedStatText(value: average, format: "%.1f", suffix: String(localized: "babies / delivery", bundle: .module), font: .title3, fontWeight: .semibold)
                    HStack(spacing: 4) {
                        Text("Deliveries:", bundle: .module)
                        AnimatedInteger(value: totals.deliveries, font: .footnote, color: .secondary)
                        Text("•", bundle: .module)
                        Text("Babies:", bundle: .module)
                        AnimatedInteger(value: totals.babies, font: .footnote, color: .secondary)
                    }
                    .font(.footnote).foregroundStyle(.secondary)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Average \(String(format: "%.1f", average)) babies per delivery. Total \(totals.deliveries) deliveries, \(totals.babies) babies.")

                if !monthlyCounts.labels.isEmpty {
                    Chart {
                        ForEach(Array(zip(monthlyCounts.labels, monthlyCounts.counts)), id: \.0) { label, count in
                            AreaMark(x: .value("Month", label), y: .value("Babies", count))
                                .foregroundStyle(LinearGradient(colors: [.storkPink.opacity(0.35), .clear], startPoint: .top, endPoint: .bottom))
                                .interpolationMethod(.catmullRom)
                            LineMark(x: .value("Month", label), y: .value("Babies", count))
                                .foregroundStyle(.storkPink)
                                .interpolationMethod(.catmullRom)
                                .symbol(Circle())
                                .symbolSize(30)
                        }
                    }
                    .frame(height: 200)
                    .chartYAxis {
                        AxisMarks(position: .leading, values: .automatic) { value in
                            AxisValueLabel(value.as(Int.self)!.description)
                        }
                    }
                    .chartXAxis {
                        AxisMarks(values: shownLabels) { value in
                            // Angle the month labels via Charts' built-in `orientation:`. A manual
                            // `.rotationEffect` here makes Charts derive a custom-UnitPoint pivot,
                            // which the iOS 27 SDK rejects with a console warning; the named
                            // orientation uses supported anchors internally.
                            AxisValueLabel(orientation: .verticalReversed) {
                                if let label = value.as(String.self) {
                                    Text(Self.abbrevLabel(label))
                                }
                            }
                        }
                    }
                    .accessibilityLabel(Text("Chart showing babies delivered over time by month", bundle: .module))
                } else {
                    EmptyCardLabel()
                }
            }
        }
    }

    private static func abbrevLabel(_ raw: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        if let date = formatter.date(from: raw) {
            formatter.dateFormat = "MM/yy"
            return formatter.string(from: date)
        }
        formatter.dateFormat = "MMM yyyy"
        if let date = formatter.date(from: raw) {
            formatter.dateFormat = "MM/yy"
            return formatter.string(from: date)
        }
        return raw
    }
}
#endif
