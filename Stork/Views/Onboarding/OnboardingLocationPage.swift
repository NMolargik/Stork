//
//  OnboardingLocationPage.swift
//  Stork
//
//  Created by Assistant on 10/2/25.
//

import SwiftUI
import CoreLocation
import UIKit

struct OnboardingLocationPage: View {
    @Environment(LocationManager.self) private var locationManager: LocationManager

    private var status: CLAuthorizationStatus { locationManager.authorizationStatus }

    private var statusInfo: (title: String, subtitle: String, symbol: String, color: Color) {
        switch status {
        case .authorizedAlways, .authorizedWhenInUse:
            return ("Location Enabled", "Thanks! We'll use your location to find nearby hospitals and local weather.", "checkmark.seal.fill", .green)
        case .denied, .restricted:
            return ("Location Disabled", "Please enable location in Settings to get the best experience.", "exclamationmark.triangle.fill", .storkOrange)
        case .notDetermined:
            return ("Permission Needed", "We need your permission to access your location.", "location.circle.fill", .storkBlue)
        @unknown default:
            return ("Unknown Status", "We couldn't determine your location permission.", "questionmark.circle.fill", .gray)
        }
    }

    private var buttonTitle: String {
        switch status {
        case .authorizedAlways, .authorizedWhenInUse:
            return "Location Enabled"
        case .denied, .restricted:
            return "Enable in Settings"
        case .notDetermined:
            return "Request Location Access"
        @unknown default:
            return "Request Location Access"
        }
    }

    var body: some View {
        NavigationStack {
            Text("Stork uses your location to find nearby hospitals and fetch local weather.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)

            Image(systemName: statusInfo.symbol)
                .resizable()
                .scaledToFit()
                .frame(width: 120, height: 120)
                .foregroundStyle(statusInfo.color)
                .padding(.vertical, 16)

            VStack(spacing: 12) {
                Button {
                    switch status {
                    case .notDetermined:
                        locationManager.requestAuthorization()
                    case .denied, .restricted:
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    default:
                        break
                    }
                } label: {
                    Text(buttonTitle)
                }
                .foregroundStyle(.white)
                .padding()
                .adaptiveGlass(tint: statusInfo.color)
                .font(.title3)
                .bold()
                .disabled(status == .authorizedAlways || status == .authorizedWhenInUse)

                if status == .denied || status == .restricted {
                    Button {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        Label("Open Settings", systemImage: "gear")
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding(.horizontal)

            Spacer()
        }
        .navigationTitle("Location")
        .padding()
    }
}

#Preview {
    NavigationStack {
        OnboardingLocationPage()
            .environment(LocationManager())
    }
}
