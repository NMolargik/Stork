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
    let allDeliveries: [Delivery]
    @AppStorage(AppStorageKeys.excludedBirthRoles) private var excludedRoles = ""

    init(deliveries: [Delivery]) { allDeliveries = deliveries }

    /// Deliveries whose role counts toward the headline total (Settings → Roles).
    private var deliveries: [Delivery] {
        let counting = BirthRoleCounting(storedValue: excludedRoles)
        return allDeliveries.filter { counting.counts($0.role) }
    }

    var body: some View {
        InsightCard(title: String(localized: "Babies per Delivery", bundle: .module), systemImage: "figure.2.and.child.holdinghands", accent: .storkPink) {
            let average = DeliveryStatistics.averageBabyCount(deliveries: deliveries)
            let monthlyCounts = DeliveryStatistics.monthlyBabyCounts(deliveries: deliveries)
            // The statistic is newest-first; the chart reads oldest to newest, left to right.
            let allLabels = Array(monthlyCounts.labels.reversed())
            let allCounts = Array(monthlyCounts.counts.reversed())
            // About six horizontal labels on every device, however many months there are.
            let stride = max(1, Int((Double(allLabels.count) / 6).rounded(.up)))
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

                if !allLabels.isEmpty {
                    Text("Babies each month", bundle: .module).font(.caption).foregroundStyle(.secondary)
                    Chart {
                        ForEach(Array(zip(allLabels, allCounts)), id: \.0) { label, count in
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
                        AxisMarks(values: .automatic) { value in
                            // Use the String initializer, not the `{ content }` closure form: in
                            // the iOS 27 SDK the closure form routes through Charts' custom
                            // UnitPoint-anchor path and logs "Custom UnitPoint values are not
                            // supported" whatever it contains. Only about six labels are shown,
                            // so they stay horizontal.
                            // Thinned here (not through the `values:` list, which a categorical
                            // axis does not honour) to every stride-th month.
                            if let label = value.as(String.self), let index = allLabels.firstIndex(of: label), index % stride == 0 {
                                AxisValueLabel(Self.abbrevLabel(label))
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
