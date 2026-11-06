//
//  OnboardingStep.swift
//  StorkCore
//
//  The ordered onboarding pages. Step Count is skipped on visionOS (no HealthKit
//  step source). There is deliberately no location page: location is requested only
//  when a Pro user attaches a weather snapshot while logging a delivery.
//

import Foundation

nonisolated public enum OnboardingStep: CaseIterable, Sendable {
    case privacy
    #if !os(visionOS)
    case health
    #endif
    case complete

    public var title: String {
        switch self {
        case .privacy: String(localized: "Your Privacy", bundle: .module)
        #if !os(visionOS)
        case .health: String(localized: "Step Count", bundle: .module)
        #endif
        case .complete: String(localized: "You're All Set", bundle: .module)
        }
    }
}
