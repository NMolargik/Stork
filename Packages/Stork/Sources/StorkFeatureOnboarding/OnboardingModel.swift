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
    public enum Direction: Sendable { case forward, backward }

    public var currentStep: OnboardingStep = .privacy
    /// Which way the last page change went, so the outgoing page slides the right way.
    public var direction: Direction = .forward
    public var isRequestingPermission = false

    public var canContinue: Bool { !isRequestingPermission }

    public init() {}

    /// Steps back to the page before the current one in `steps`, if any.
    public func goBack(in steps: [OnboardingStep]) {
        guard let index = steps.firstIndex(of: currentStep), index > 0 else { return }
        direction = .backward
        currentStep = steps[index - 1]
    }

    /// Leaves the Step Count page without asking for access (it can be granted later in Settings).
    public func skipHealth() {
        guard currentStep == .health else { return }
        direction = .forward
        currentStep = .complete
    }

    /// Advances the flow, requesting permissions inline. On the health page the user taps
    /// Continue again after the system dialog resolves.
    public func handleContinueTapped(healthManager: HealthManager) async {
        direction = .forward
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
