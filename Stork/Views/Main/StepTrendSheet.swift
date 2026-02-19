//
//  StepTrendSheet.swift
//  Stork
//
//  Created by Nick Molargik on 2/16/26.
//

#if !os(visionOS)
import SwiftUI
import Charts

struct StepTrendSheet: View {
    @Environment(HealthManager.self) private var healthManager: HealthManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                if !healthManager.isAuthorized {
                    ContentUnavailableView(
                        "Steps Unavailable",
                        systemImage: "figure.walk",
                        description: Text("Grant Stork access to step data in the Health app, or pair an Apple Watch to track steps.")
                    )
                } else if healthManager.weeklyStepCounts.isEmpty {
                    ProgressView("Loading steps…")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    let weekTotal = healthManager.weeklyStepCounts.reduce(0) { $0 + $1.steps }
                    let dailyAverage = weekTotal / max(healthManager.weeklyStepCounts.count, 1)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("7-Day Average")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Text("\(dailyAverage.formatted()) steps")
                            .font(.title2)
                            .bold()
                            .monospacedDigit()
                    }
                    .padding(.horizontal)

                    Chart {
                        ForEach(healthManager.weeklyStepCounts, id: \.date) { entry in
                            AreaMark(
                                x: .value("Day", entry.date, unit: .day),
                                y: .value("Steps", entry.steps)
                            )
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.storkPurple.opacity(0.35), .clear],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .interpolationMethod(.catmullRom)

                            LineMark(
                                x: .value("Day", entry.date, unit: .day),
                                y: .value("Steps", entry.steps)
                            )
                            .foregroundStyle(.storkPurple)
                            .interpolationMethod(.catmullRom)
                            .symbol(Circle())
                            .symbolSize(30)
                        }
                    }
                    .frame(height: 200)
                    .chartYAxis {
                        AxisMarks(position: .leading)
                    }
                    .chartXAxis {
                        AxisMarks(values: .stride(by: .day)) { value in
                            AxisValueLabel(format: .dateTime.weekday(.abbreviated))
                        }
                    }
                    .padding(.horizontal)

                    Spacer()
                }
            }
            .padding(.top)
            .navigationTitle("Steps This Week")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                    .foregroundStyle(.storkPurple)
                    .keyboardShortcut(.escape, modifiers: [])
                    .hoverEffect(.highlight)
                }
            }
        }
        .task {
            await healthManager.fetchWeeklyStepCounts()
        }
    }
}
#endif
