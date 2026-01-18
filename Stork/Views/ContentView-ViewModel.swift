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
        var appStage: AppStage = .start
        var cloudCheckMessage: String = "Checking for existing data..."

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

        func prepareApp(migrationManager: MigrationManager) async {
            // Check for Firebase migration first
            if migrationManager.isAuthenticated {
                await MainActor.run { self.appStage = .migration }
                return
            }

            guard let userManager else { return }

            // Quick local check first - user might already be cached
            await userManager.refresh()
            if userManager.hasExistingData() {
                await transitionToMain()
                return
            }

            // Show the "checking cloud" state to user
            await MainActor.run {
                withAnimation(.easeInOut(duration: 0.3)) {
                    self.cloudCheckMessage = "Checking iCloud..."
                    self.appStage = .checkingCloud
                }
            }

            // If iCloud is available, wait for remote changes or timeout
            if let cloudSyncManager, cloudSyncManager.isCloudAvailable {
                await MainActor.run {
                    self.cloudCheckMessage = "Syncing with iCloud..."
                }

                // Wait up to 10 seconds for a remote change notification
                let receivedRemoteChange = await cloudSyncManager.waitForRemoteChange(timeout: 10)

                if receivedRemoteChange {
                    // Remote data arrived - refresh and check again
                    await userManager.refresh()
                    if userManager.hasExistingData() {
                        await transitionToMain()
                        return
                    }
                }

                // Even if no notification, poll a few more times with increasing delays
                // CloudKit can sometimes sync without firing the notification
                await MainActor.run {
                    self.cloudCheckMessage = "Looking for your data..."
                }

                for delay in [0.5, 1.0, 1.5, 2.0] {
                    try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                    await userManager.refresh()
                    if userManager.hasExistingData() {
                        await transitionToMain()
                        return
                    }
                }
            } else {
                // No iCloud - just do a brief local check
                await userManager.restoreFromCloud(timeout: 3, pollInterval: 0.5)
                if userManager.hasExistingData() {
                    await transitionToMain()
                    return
                }
            }

            // No existing data found - go to splash
            await MainActor.run {
                withAnimation(.easeInOut(duration: 0.3)) {
                    self.appStage = .splash
                }
            }
        }

        private func transitionToMain() async {
            await MainActor.run {
                withAnimation(.easeInOut(duration: 0.3)) {
                    self.appStage = .main
                }
            }
        }
        
        func resetApplicationStage() {
            appStage = .splash
            resetApplication?()
        }
        
        /// Attempts login and returns an optional error message (nil on success)
        func attemptLogIn(emailAddress: String, password: String, migrationManager: MigrationManager) async -> String? {
            do {
                try await migrationManager.logInUserWithEmail(emailAddress: emailAddress, password: password)
                await MainActor.run {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        self.appStage = .migration
                    }
                }
                return nil
            } catch {
                if let authError = error as? AuthError { return authError.message }
                return error.localizedDescription
            }
        }
    }
}
