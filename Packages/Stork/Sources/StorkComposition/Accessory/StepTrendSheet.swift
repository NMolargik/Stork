//
//  StepTrendSheet.swift
//  StorkComposition
//
//  Weekly step trend chart.
//

#if os(iOS) && canImport(HealthKit)
import SwiftUI
import Charts
import StorkDesignSystem
import StorkServices

struct StepTrendSheet: View {
    let manager: HealthManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                if !manager.isAuthorized {
                    ContentUnavailableView("Steps Unavailable", systemImage: "figure.walk",
                                           description: Text("Grant Stork access to step data in the Health app, or pair an Apple Watch to track steps."))
                } else if manager.weeklyStepCounts.isEmpty {
                    ProgressView("Loading steps…").frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    let weekTotal = manager.weeklyStepCounts.reduce(0) { $0 + $1.steps }
                    let dailyAverage = weekTotal / max(manager.weeklyStepCounts.count, 1)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("7-Day Average").font(.caption).foregroundStyle(.secondary)
                        Text("\(dailyAverage.formatted()) steps").font(.title2).bold().monospacedDigit()
                    }
                    .padding(.horizontal)
                    .accessibilityElement(children: .combine)

                    Chart {
                        ForEach(manager.weeklyStepCounts, id: \.date) { entry in
                            AreaMark(x: .value("Day", entry.date, unit: .day), y: .value("Steps", entry.steps))
                                .foregroundStyle(LinearGradient(colors: [.storkPurple.opacity(0.35), .clear], startPoint: .top, endPoint: .bottom))
                                .interpolationMethod(.catmullRom)
                            LineMark(x: .value("Day", entry.date, unit: .day), y: .value("Steps", entry.steps))
                                .foregroundStyle(.storkPurple)
                                .interpolationMethod(.catmullRom)
                                .symbol(Circle()).symbolSize(30)
                        }
                    }
                    .frame(height: 200)
                    .chartYAxis { AxisMarks(position: .leading) }
                    .chartXAxis { AxisMarks(values: .stride(by: .day)) { _ in AxisValueLabel(format: .dateTime.weekday(.abbreviated)) } }
                    .padding(.horizontal)
                    .accessibilityLabel("Daily step counts for the last 7 days")

                    Spacer()
                }
            }
            .padding(.top)
            .navigationTitle("Steps This Week")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: { Image(systemName: "xmark") }
                        .keyboardShortcut(.escape, modifiers: [])
                        .accessibilityLabel("Close")
                }
            }
        }
        .task { await manager.fetchWeeklyStepCounts() }
    }
}
#endif
