//
//  OnboardingStep.swift
//  StorkCore
//
//  The ordered onboarding pages. Step Count is skipped on visionOS (no HealthKit
//  step source).
//

import Foundation

nonisolated public enum OnboardingStep: CaseIterable, Sendable {
    case privacy
    case location
    #if !os(visionOS)
    case health
    #endif
    case complete

    public var title: String {
        switch self {
        case .privacy: String(localized: "Your Privacy", bundle: .module)
        case .location: String(localized: "Location", bundle: .module)
        #if !os(visionOS)
        case .health: String(localized: "Step Count", bundle: .module)
        #endif
        case .complete: String(localized: "You're All Set", bundle: .module)
        }
    }
}
