//
//  ContentView-ViewModel.swift
//  Stork
//

import SwiftUI

extension ContentView {
    @Observable
    final class ViewModel {
        var appStage: AppStage = .splash

        var leadingTransition: AnyTransition {
            .asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity)
            )
        }

        func advance(to stage: AppStage) {
            withAnimation(.easeInOut(duration: 0.3)) {
                appStage = stage
            }
        }

        /// Returning users go straight to the app; iCloud sync continues
        /// in the background with a toast instead of a blocking screen.
        func prepareApp(isOnboardingComplete: Bool) {
            appStage = isOnboardingComplete ? .main : .splash
        }
    }
}
