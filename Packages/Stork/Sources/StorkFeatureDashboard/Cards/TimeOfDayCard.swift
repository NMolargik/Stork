//
//  TimeOfDayCard.swift
//  StorkFeatureDashboard
//

#if os(iOS)
import SwiftUI
import StorkCore
import StorkDesignSystem

struct TimeOfDayCard: View {
    let deliveries: [Delivery]

    var body: some View {
        InsightCard(title: "Time of Day", systemImage: "clock.fill", accent: .storkPurple) {
            let stats = DeliveryStatistics.timeOfDayStats(deliveries: deliveries)
            VStack(alignment: .leading, spacing: 12) {
                if stats.total > 0 {
                    if let peakHour = stats.peakHour {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Peak Hour").font(.caption).foregroundStyle(.secondary)
                                Text(formatHour(peakHour)).font(.title2.bold()).foregroundStyle(.storkPurple)
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 2) {
                                Text("\(stats.peakCount)").font(.title2.bold())
                                Text("deliveries").font(.caption).foregroundStyle(.secondary)
                            }
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("Peak hour is \(formatHour(peakHour)) with \(stats.peakCount) deliveries")
                    }

                    Divider()

                    let shifts = stats.shiftBreakdown
                    VStack(alignment: .leading, spacing: 8) {
                        Text("By Shift").font(.caption.weight(.semibold)).foregroundStyle(.secondary)
                        HStack(spacing: 8) {
                            ShiftPill(label: "Night", count: shifts.night, total: stats.total, color: .indigo)
                            ShiftPill(label: "Morning", count: shifts.morning, total: stats.total, color: .orange)
                        }
                        HStack(spacing: 8) {
                            ShiftPill(label: "Afternoon", count: shifts.afternoon, total: stats.total, color: .yellow)
                            ShiftPill(label: "Evening", count: shifts.evening, total: stats.total, color: .blue)
                        }
                    }
                } else {
                    EmptyCardLabel()
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

    private struct ShiftPill: View {
        let label: String
        let count: Int
        let total: Int
        let color: Color

        var body: some View {
            let percentage = total > 0 ? Double(count) / Double(total) * 100 : 0
            HStack(spacing: 4) {
                Circle().fill(color).frame(width: 8, height: 8)
                Text(label).font(.caption)
                Text(String(format: "%.0f%%", percentage)).font(.caption.bold()).foregroundStyle(color)
            }
            .padding(.horizontal, 8).padding(.vertical, 4)
            .background(.ultraThinMaterial, in: Capsule())
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(label) shift: \(String(format: "%.0f", percentage)) percent, \(count) deliveries")
        }
    }
}
#endif
