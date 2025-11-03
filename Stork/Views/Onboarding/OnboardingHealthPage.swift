//
//  OnboardingHealthPage.swift
//  Stork
//
//  Created by Assistant on 10/2/25.
//

import SwiftUI
import UIKit

struct OnboardingHealthPage: View {
    @Environment(HealthManager.self) private var healthManager: HealthManager

    private var statusInfo: (title: String, subtitle: String, symbol: String, color: Color) {
        if healthManager.isAuthorized {
            return ("Health Connected", "Thanks! We'll read your step count to power the pedometer.", "checkmark.seal.fill", .green)
        }
        if healthManager.lastError != nil {
            return ("Access Denied", "Please enable Health permissions in Settings to connect.", "exclamationmark.triangle.fill", .storkOrange)
        }
        return ("Permission Needed", "We need your permission to read your step count.", "heart.fill", .pink)
    }

    private var primaryButtonTitle: String {
        if healthManager.isAuthorized { return "Connected" }
        if healthManager.lastError != nil { return "Enable in Settings" }
        return "Connect Apple Health"
    }

    var body: some View {
        NavigationStack {
            Text("Allow Stork to read your step count so we can show a pedometer.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            
            Image(systemName: statusInfo.symbol)
                .resizable()
                .scaledToFit()
                .frame(width: 120, height: 120)
                .foregroundStyle(statusInfo.color)
                .shadow(radius: 8)
                .padding(.vertical, 16)

            VStack(spacing: 12) {
                Button {
                    if healthManager.isAuthorized {
                        // No action when already connected
                    } else if healthManager.lastError != nil {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    } else {
                        connectHealth()
                    }
                } label: {
                    Text(primaryButtonTitle)
                }
                .foregroundStyle(.white)
                .padding()
                .adaptiveGlass(tint: statusInfo.color)
                .font(.title3)
                .bold()
                .disabled(healthManager.isAuthorized)

                if let error = healthManager.lastError, !healthManager.isAuthorized {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.yellow)
                        Text(error.localizedDescription)
                            .multilineTextAlignment(.leading)
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(.ultraThinMaterial)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(Color.secondary.opacity(0.2))
                    )
                }
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
        .navigationTitle("Apple Health")
        .padding()
        .task {
            if !healthManager.isAuthorized {
                await healthManager.requestAuthorization()
            }
        }
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
