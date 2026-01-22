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

        // Actions
        func handleContinueTapped() {
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

    }
}
