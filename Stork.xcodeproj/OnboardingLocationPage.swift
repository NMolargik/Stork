//
//  OnboardingLocationPage.swift
//  Stork
//
//  Created by Assistant on 10/2/25.
//

import SwiftUI
import CoreLocation

struct OnboardingLocationPage: View {
    @Environment(LocationManager.self) private var locationManager: LocationManager

    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Text("Enable Location Access")
                    .font(.title2).bold()
                Text("Stork uses your location to find nearby hospitals and fetch local weather.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 32)

            Image(systemName: "location.circle.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 120, height: 120)
                .foregroundStyle(.blue)
                .padding(.vertical, 16)

            VStack(spacing: 12) {
                Button(action: {
                    locationManager.requestAuthorization()
                }) {
                    Text("Allow Location")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(.horizontal)

            Text("Current status: \(statusDescription(locationManager.authorizationStatus))")
                .font(.footnote)
                .foregroundStyle(.secondary)

            Spacer()
        }
        .padding()
    }

    private func statusDescription(_ status: CLAuthorizationStatus) -> String {
        switch status {
        case .notDetermined: return "Not determined"
        case .restricted: return "Restricted"
        case .denied: return "Denied"
        case .authorizedAlways: return "Authorized Always"
        case .authorizedWhenInUse: return "Authorized When In Use"
        @unknown default: return "Unknown"
        }
    }
}

#Preview {
    NavigationStack {
        OnboardingLocationPage()
            .environment(LocationManager())
    }
}
