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
        case .privacy: "Your Privacy"
        case .location: "Location"
        #if !os(visionOS)
        case .health: "Step Count"
        #endif
        case .complete: "You're All Set"
        }
    }
}
