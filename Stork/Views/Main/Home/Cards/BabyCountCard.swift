//
//  BabyCountCard.swift
//  Stork
//
//  Created by Nick Molargik on 11/5/25.
//

import SwiftUI
import Charts
import SwiftData

struct BabyCountCard: View {
    @Environment(DeliveryManager.self) private var deliveryManager: DeliveryManager
    @Environment(\.horizontalSizeClass) private var hSizeClass
    let viewModel: HomeView.ViewModel

    var body: some View {
        InsightCard(title: "Babies per Delivery", systemImage: "figure.2.and.child.holdinghands", accent: .storkPink) {
            let average = viewModel.averageBabyCount(deliveries: deliveryManager.deliveries)
            let monthlyCounts = viewModel.monthlyBabyCounts(deliveries: deliveryManager.deliveries)
            // Determine which x-axis labels to show (skip some on compact to avoid truncation)
            let allLabels = monthlyCounts.labels
            let stride = (hSizeClass == .compact && allLabels.count > 8) ? 2 : 1
            let shownLabels = allLabels.enumerated().compactMap { index, label in
                index % stride == 0 ? label : nil
            }
            let totals = viewModel.deliveryAndBabyTotals(deliveries: deliveryManager.deliveries)
            let totalDeliveries = totals.deliveries
            let totalBabies = totals.babies

            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Average")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    AnimatedStatText(value: average, format: "%.1f", suffix: "babies / delivery", font: .title3, fontWeight: .semibold)
                    HStack(spacing: 4) {
                        Text("Deliveries:")
                        AnimatedInteger(value: totalDeliveries, font: .footnote, color: .secondary)
                        Text("•")
                        Text("Babies:")
                        AnimatedInteger(value: totalBabies, font: .footnote, color: .secondary)
                    }
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Average \(String(format: "%.1f", average)) babies per delivery. Total \(totalDeliveries) deliveries, \(totalBabies) babies.")

                if !monthlyCounts.labels.isEmpty {
                    Chart {
                        ForEach(Array(zip(monthlyCounts.labels, monthlyCounts.counts)), id: \.0) { label, count in
                            AreaMark(
                                x: .value("Month", label),
                                y: .value("Babies", count)
                            )
                            .foregroundStyle(LinearGradient(colors: [.storkPink.opacity(0.35), .clear], startPoint: .top, endPoint: .bottom))
                            .interpolationMethod(.catmullRom)

                            LineMark(
                                x: .value("Month", label),
                                y: .value("Babies", count)
                            )
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
                            AxisValueLabel(anchor: .bottom) {
                                if let label = value.as(String.self) {
                                    Text(Self.abbrevLabel(label))
                                        .rotationEffect(.degrees(45))
                                }
                            }
                        }
                    }
                    .accessibilityLabel("Chart showing babies delivered over time by month")
                } else {
                    Label("No deliveries logged yet.", systemImage: "tray.fill")
                        .foregroundStyle(.secondary)
                        .labelStyle(.titleOnly)
                }
            }
        }
    }
    
    private static func abbrevLabel(_ raw: String) -> String {
        // Expect inputs like "October 2025" or "Oct 2025"
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        if let date = formatter.date(from: raw) {
            formatter.dateFormat = "MM/yy"
            return formatter.string(from: date)
        } else {
            // Try short month fallback
            formatter.dateFormat = "MMM yyyy"
            if let date = formatter.date(from: raw) {
                formatter.dateFormat = "MM/yy"
                return formatter.string(from: date)
            }
        }
        return raw
    }
}

#Preview {
    let container: ModelContainer = {
        let schema = Schema([Delivery.self, User.self, Baby.self])
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        return try! ModelContainer(for: schema, configurations: [configuration])
    }()
    let context = ModelContext(container)
    
    BabyCountCard(viewModel: HomeView.ViewModel())
        .environment(DeliveryManager(context: context))
}
