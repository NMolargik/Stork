//
//  OnboardingView-ViewModel.swift
//  Stork
//
//  Created by Nick Molargik on 10/3/25.
//

import SwiftUI
import CoreLocation

extension OnboardingView {
    @Observable
    class ViewModel {
        var currentStep: OnboardingStep = .privacy
        var isRequestingPermission: Bool = false

        var canContinue: Bool {
            !isRequestingPermission
        }

        // Actions

        /// Handles Continue button tap. Returns true if we should wait for permission dialog.
        /// - On location page: if not determined, requests permission and stays on page
        /// - On health page: if not yet requested, requests permission and stays on page
        @MainActor
        func handleContinueTapped(
            locationManager: LocationManager,
            healthManager: HealthManager
        ) async {
            switch currentStep {
            case .privacy:
                currentStep = .location

            case .location:
                let status = locationManager.authorizationStatus
                if status == .notDetermined {
                    // Request permission - user must tap Continue again after dialog
                    isRequestingPermission = true
                    locationManager.requestAuthorization()
                    // Give the system time to show the dialog and update status
                    try? await Task.sleep(for: .milliseconds(500))
                    isRequestingPermission = false
                    // Stay on page - user will see updated UI and tap Continue again
                } else {
                    // Already determined (authorized or denied), move forward
                    // Skip health step on iPad and visionOS
                    #if os(visionOS)
                    currentStep = .complete
                    #elseif os(iOS)
                    if UIDevice.current.userInterfaceIdiom == .pad {
                        currentStep = .complete
                    } else {
                        currentStep = .health
                    }
                    #else
                    currentStep = .health
                    #endif
                }

            case .health:
                let hasBeenRequested = healthManager.isAuthorized || healthManager.lastError != nil
                if !hasBeenRequested {
                    // Request permission - user must tap Continue again after dialog
                    isRequestingPermission = true
                    await healthManager.requestAuthorization()
                    if healthManager.isAuthorized {
                        healthManager.startObservingStepCount()
                    }
                    isRequestingPermission = false
                    // Stay on page - user will see updated UI and tap Continue again
                } else {
                    // Already requested (authorized or denied), move forward
                    currentStep = .complete
                }

            case .complete:
                break
            }
        }
    }
}
