//
//  OnboardingModel.swift
//  StorkFeatureOnboarding
//
//  Drives the onboarding step machine and requests location/health permissions.
//

#if os(iOS)
import Foundation
import Observation
import StorkCore
import StorkServices

@MainActor
@Observable
public final class OnboardingModel {
    public var currentStep: OnboardingStep = .privacy
    public var isRequestingPermission = false

    public var canContinue: Bool { !isRequestingPermission }

    public init() {}

    /// Advances the flow, requesting permissions inline. On the location/health pages the
    /// user taps Continue again after the system dialog resolves.
    public func handleContinueTapped(locationManager: LocationManager, healthManager: HealthManager) async {
        switch currentStep {
        case .privacy:
            currentStep = .location

        case .location:
            if locationManager.authorizationStatus == .notDetermined {
                isRequestingPermission = true
                locationManager.requestAuthorization()
                try? await Task.sleep(for: .milliseconds(500))
                isRequestingPermission = false
            } else {
                currentStep = healthManager.isStepTrackingSupported ? .health : .complete
            }

        case .health:
            if !healthManager.hasRequestedAuthorization {
                isRequestingPermission = true
                await healthManager.requestAuthorization()
                if healthManager.isAuthorized { healthManager.startObservingStepCount() }
                isRequestingPermission = false
            } else {
                currentStep = .complete
            }

        case .complete:
            break
        }
    }
}
#endif
