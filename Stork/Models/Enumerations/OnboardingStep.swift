//
//  OnboardingStep.swift
//  Stork
//
//  Created by Nick Molargik on 10/3/25.
//

import Foundation

enum OnboardingStep: CaseIterable {
    case privacy
    case location
    #if !os(visionOS)
    case health
    #endif
    case complete

    var title: String {
        switch self {
        case .privacy: return "Your Privacy"
        case .location: return "Location"
        #if !os(visionOS)
        case .health: return "Step Count"
        #endif
        case .complete: return "You're All Set"
        }
    }
}
