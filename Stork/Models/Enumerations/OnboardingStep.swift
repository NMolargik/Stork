//
//  OnboardingStep.swift
//  Stork
//
//  Created by Nick Molargik on 10/3/25.
//

import Foundation

enum OnboardingStep: CaseIterable {
    case privacy
    case userInfo
    case location
    case health
    case complete

    var title: String {
        switch self {
        case .privacy: return "Your Privacy"
        case .userInfo: return "About You"
        case .location: return "Location"
        case .health: return "Step Count"
        case .complete: return "You're All Set"
        }
    }
}
