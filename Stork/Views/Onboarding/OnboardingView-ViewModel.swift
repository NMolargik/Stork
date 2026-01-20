//
//  OnboardingView-ViewModel.swift
//  Stork
//
//  Created by Nick Molargik on 10/3/25.
//

import SwiftUI

extension OnboardingView {
    @Observable
    class ViewModel {
        var currentStep: OnboardingStep = .privacy

        var canContinue: Bool {
            switch currentStep {
            case .privacy, .location, .health, .complete:
                return true
            }
        }

        var showsSkip: Bool {
            switch currentStep {
            case .location, .health:
                return true
            case .privacy, .complete:
                return false
            }
        }

        // Actions
        func handleContinueTapped(userManager: UserManager) {
            switch currentStep {
            case .privacy:
                currentStep = .location
            case .location:
                currentStep = .health
            case .health:
                currentStep = .complete
            case .complete:
                break
            }
        }

        func handleSkipTapped() {
            switch currentStep {
            case .location:
                currentStep = .health
            case .health:
                currentStep = .complete
            case .privacy, .complete:
                break
            }
        }
    }
}
