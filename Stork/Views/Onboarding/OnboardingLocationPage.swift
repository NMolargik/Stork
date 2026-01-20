//
//  OnboardingLocationPage.swift
//  Stork
//
//  Created by Nick Molargik on 10/2/25.
//

import SwiftUI
import CoreLocation
import UIKit

struct OnboardingLocationPage: View {
    @Environment(LocationManager.self) private var locationManager

    private var status: CLAuthorizationStatus { locationManager.authorizationStatus }

    private var statusConfig: (icon: String, color: Color, title: String, description: String) {
        switch status {
        case .authorizedAlways, .authorizedWhenInUse:
            return (
                "checkmark.circle.fill",
                .green,
                "Location Enabled",
                "We'll use your location for local weather."
            )
        case .denied, .restricted:
            return (
                "location.slash.fill",
                .orange,
                "Location Disabled",
                "Enable location in Settings to get weather data."
            )
        case .notDetermined:
            return (
                "location.circle.fill",
                .storkBlue,
                "Enable Location",
                "Allow location access to see local weather on your home screen."
            )
        @unknown default:
            return (
                "questionmark.circle.fill",
                .secondary,
                "Unknown Status",
                "We couldn't determine your location settings."
            )
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Header
                VStack(spacing: 16) {
                    Image(systemName: statusConfig.icon)
                        .font(.system(size: 64))
                        .foregroundStyle(statusConfig.color)
                        .contentTransition(.symbolEffect(.replace))
                        .accessibilityHidden(true)

                    Text(statusConfig.title)
                        .font(.title.bold())

                    Text(statusConfig.description)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(.top, 24)

                // Features
                VStack(spacing: 0) {
                    FeatureRow(
                        icon: "sun.max.fill",
                        iconColor: .yellow,
                        title: "Local Weather",
                        description: "See current conditions on your dashboard."
                    )
                }
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .frame(maxWidth: 500)
                .padding(.horizontal, 20)

                // Action Button
                if status == .notDetermined {
                    Button {
                        Haptics.mediumImpact()
                        locationManager.requestAuthorization()
                    } label: {
                        Label("Allow Location Access", systemImage: "location.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.storkBlue)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .frame(maxWidth: 500)
                    .padding(.horizontal, 20)
                } else if status == .denied || status == .restricted {
                    Button {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        Label("Open Settings", systemImage: "gear")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.secondary.opacity(0.2))
                            .foregroundStyle(.primary)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .frame(maxWidth: 500)
                    .padding(.horizontal, 20)
                }

                Spacer(minLength: 120)
            }
            .frame(maxWidth: .infinity)
        }
        .scrollIndicators(.hidden)
    }
}

private struct FeatureRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(iconColor)
                .frame(width: 28)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    OnboardingLocationPage()
        .environment(LocationManager())
}
