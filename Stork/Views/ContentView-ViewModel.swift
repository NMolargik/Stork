//
//  ContentView-ViewModel.swift
//  Stork
//
//  Created by Nick Molargik on 8/30/25.
//

import SwiftUI
import Observation

extension ContentView {
    @Observable
    class ViewModel {
        // MARK: - App State
        var appStage: AppStage = .splash

        // MARK: - Dependencies
        var userManager: UserManager?
        var cloudSyncManager: CloudSyncManager?
        var resetApplication: (() -> Void)?

        // MARK: - Configuration
        func configure(
            userManager: UserManager,
            cloudSyncManager: CloudSyncManager,
            resetApplication: @escaping () -> Void
        ) {
            self.userManager = userManager
            self.cloudSyncManager = cloudSyncManager
            self.resetApplication = resetApplication
        }

        // MARK: - Transitions
        var leadingTransition: AnyTransition {
            .asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity)
            )
        }

        func prepareApp(isOnboardingComplete: Bool) async {
            await MainActor.run {
                appStage = isOnboardingComplete ? .syncing : .splash
            }
        }

        func resetApplicationStage() {
            appStage = .splash
            resetApplication?()
        }
    }
}
