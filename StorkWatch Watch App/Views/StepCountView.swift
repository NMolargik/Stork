//
//  StepCountView.swift
//  StorkWatch Watch App
//
//  Created by Nick Molargik on 1/17/26.
//

import SwiftUI

struct StepCountView: View {
    @Bindable var healthManager: WatchHealthManager

    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Image(systemName: "figure.walk")
                    .foregroundStyle(.green)
                Text("Steps")
                    .font(.headline)
            }

            if healthManager.isAuthorized {
                // Step count display
                ZStack {
                    Circle()
                        .stroke(Color.green.opacity(0.3), lineWidth: 8)
                        .frame(width: 100, height: 100)

                    // Progress ring (goal: 10,000 steps)
                    Circle()
                        .trim(from: 0, to: min(Double(healthManager.todayStepCount) / 10000.0, 1.0))
                        .stroke(Color.green, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .frame(width: 100, height: 100)
                        .rotationEffect(.degrees(-90))

                    VStack(spacing: 2) {
                        Text("\(healthManager.todayStepCount)")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .monospacedDigit()
                        Text("steps")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }

                // Goal progress
                let progress = min(Double(healthManager.todayStepCount) / 10000.0 * 100, 100)
                Text(String(format: "%.0f%% of 10K goal", progress))
                    .font(.caption)
                    .foregroundStyle(.secondary)

            } else {
                // Not authorized
                VStack(spacing: 12) {
                    Image(systemName: "heart.text.square")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)

                    Text("Health Access Required")
                        .font(.subheadline)
                        .multilineTextAlignment(.center)

                    Text("Enable in Watch Settings > Privacy > Health")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)

                    Button("Request Access") {
                        Task {
                            await healthManager.requestAuthorization()
                            healthManager.startObservingStepCount()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                }
            }
        }
        .padding()
    }
}

#Preview {
    StepCountView(healthManager: WatchHealthManager())
}
