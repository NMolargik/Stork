//
//  TimeOfDayCard.swift
//  Stork
//
//  Created by Nick Molargik on 1/17/26.
//

import SwiftUI
import SwiftData

struct TimeOfDayCard: View {
    @Environment(DeliveryManager.self) private var deliveryManager: DeliveryManager
    let viewModel: DashboardView.ViewModel

    var body: some View {
        InsightCard(title: "Time of Day", systemImage: "clock.fill", accent: .storkPurple) {
            let stats = viewModel.timeOfDayStats(deliveries: deliveryManager.deliveries)
            VStack(alignment: .leading, spacing: 12) {
                if stats.total > 0 {
                    // Peak hour display
                    if let peakHour = stats.peakHour {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Peak Hour")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(formatHour(peakHour))
                                    .font(.title2.bold())
                                    .foregroundStyle(.storkPurple)
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 2) {
                                Text("\(stats.peakCount)")
                                    .font(.title2.bold())
                                    .foregroundStyle(.primary)
                                Text("deliveries")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("Peak hour is \(formatHour(peakHour)) with \(stats.peakCount) deliveries")
                    }

                    Divider()

                    // Shift breakdown
                    let shifts = stats.shiftBreakdown
                    VStack(alignment: .leading, spacing: 8) {
                        Text("By Shift")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)

                        HStack(spacing: 8) {
                            shiftPill(label: "Night", count: shifts.night, total: stats.total, color: .indigo)
                            shiftPill(label: "Morning", count: shifts.morning, total: stats.total, color: .orange)
                        }
                        HStack(spacing: 8) {
                            shiftPill(label: "Afternoon", count: shifts.afternoon, total: stats.total, color: .yellow)
                            shiftPill(label: "Evening", count: shifts.evening, total: stats.total, color: .blue)
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

    private func formatHour(_ hour: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h a"
        var components = DateComponents()
        components.hour = hour
        if let date = Calendar.current.date(from: components) {
            return formatter.string(from: date)
        }
        return "\(hour):00"
    }

    private func shiftPill(label: String, count: Int, total: Int, color: Color) -> some View {
        let percentage = total > 0 ? Double(count) / Double(total) * 100 : 0
        return HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text("\(label)")
                .font(.caption)
            Text(String(format: "%.0f%%", percentage))
                .font(.caption.bold())
                .foregroundStyle(color)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(.ultraThinMaterial, in: Capsule())
        .accessibilityLabel("\(label) shift: \(String(format: "%.0f", percentage)) percent, \(count) deliveries")
    }
}

#Preview {
    let container: ModelContainer = {
        let schema = Schema([Delivery.self, Baby.self])
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        return try! ModelContainer(for: schema, configurations: [configuration])
    }()
    let context = ModelContext(container)

    TimeOfDayCard(viewModel: DashboardView.ViewModel())
        .environment(DeliveryManager(context: context))
}
