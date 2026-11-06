//
//  OnboardingModel.swift
//  StorkFeatureOnboarding
//
//  Drives the onboarding step machine and requests the Health permission. Location is
//  not requested during onboarding (only when a Pro user attaches a weather snapshot).
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

    /// Advances the flow, requesting permissions inline. On the health page the user taps
    /// Continue again after the system dialog resolves.
    public func handleContinueTapped(healthManager: HealthManager) async {
        switch currentStep {
        case .privacy:
            currentStep = healthManager.isStepTrackingSupported ? .health : .complete

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
