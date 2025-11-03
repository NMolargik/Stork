//
//  OnboardingHealthPage.swift
//  Stork
//
//  Created by Assistant on 10/2/25.
//

import SwiftUI

struct OnboardingHealthPage: View {
    @Environment(HealthManager.self) private var healthManager: HealthManager

    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Text("Connect Apple Health")
                    .font(.title2).bold()
                Text("Allow Stork to read your step count so we can show a pedometer.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 32)

            Image(systemName: "figure.walk.circle.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 120, height: 120)
                .foregroundStyle(.green)
                .padding(.vertical, 16)

            VStack(spacing: 12) {
                Button(action: connectHealth) {
                    Text(healthManager.isAuthorized ? "Connected" : "Connect Apple Health")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(.horizontal)

            if healthManager.isAuthorized {
                VStack(spacing: 8) {
                    Text("Today's Steps")
                        .font(.headline)
                    Text("\(healthManager.todayStepCount)")
                        .font(.largeTitle).bold()
                }
                .padding(.top, 8)
            }

            Spacer()
        }
        .padding()
    }

    private func connectHealth() {
        Task { @MainActor in
            await healthManager.requestAuthorization()
            if healthManager.isAuthorized {
                healthManager.startObservingStepCount()
            }
        }
    }
}

#Preview {
    NavigationStack {
        OnboardingHealthPage()
            .environment(HealthManager())
    }
}
