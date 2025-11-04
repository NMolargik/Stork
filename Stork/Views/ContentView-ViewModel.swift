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
        
        // MARK: - Dependencies
        var userManager: UserManager?
        var resetApplication: (() -> Void)?
        
        // MARK: - Configuration
        func configure(userManager: UserManager, resetApplication: @escaping () -> Void) {
            self.userManager = userManager
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
            if migrationManager.isAuthenticated {
                await MainActor.run { self.appStage = .migration }
                return
            }
            guard let userManager else { return }
            
            // First try a quick local refresh (in case we already have the user cached)
            await userManager.refresh()
            
            // If not found yet, allow iCloud a bit more time to hydrate.
            if userManager.currentUser == nil {
                // Give CloudKit/SwiftData time to surface the user record.
                // Increased timeout and faster polling to catch "appears a second later" cases.
                await userManager.restoreFromCloud(timeout: 6, pollInterval: 0.5)
                
                // Defensive: brief retry loop after restore to cover racey arrivals.
                let deadline = Date().addingTimeInterval(2.0)
                while userManager.currentUser == nil && Date() < deadline {
                    await userManager.refresh()
                    if userManager.currentUser != nil { break }
                    try? await Task.sleep(nanoseconds: 300_000_000) // 0.3s
                }
            }
            
            if userManager.currentUser != nil {
                await MainActor.run {
                    withAnimation(.easeInOut(duration: 0.3)) { self.appStage = .main }
                }
            } else {
                await MainActor.run {
                    withAnimation(.easeInOut(duration: 0.3)) { self.appStage = .splash }
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
