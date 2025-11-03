//
//  UserManager.swift
//  Stork
//
//  Created by Nick Molargik on 9/28/25.
//

import Observation
import Foundation
import SwiftData

@MainActor
@Observable
class UserManager {
    // MARK: - Dependencies
    @ObservationIgnored
    let context: ModelContext

    private(set) var currentUser: User?
    
    var isRefreshing: Bool = false
    var isRestoringFromCloud: Bool = false
    
    init(context: ModelContext) {
        self.context = context
        Task {
            await refresh()
            print("User at start: \(currentUser.debugDescription)")
        }
    }
    
    // MARK: - Refresh
    func refresh() async {
        do {
            self.isRefreshing = true
            let desc = FetchDescriptor<User>()
            let fetched = try context.fetch(desc)
            // Enforce singleton invariant: pick the first if any exist.
            self.currentUser = fetched.first
            print("User after iCloud fetch: \(currentUser.debugDescription)")
            
            // Optional safety: if more than one slipped in via sync/merge, keep the first and delete extras.
            if fetched.count > 1 {
                for extra in fetched.dropFirst() {
                    context.delete(extra)
                }
                try? context.save()
            }
            self.isRefreshing = false
        } catch {
            let userError = UserError.fetchFailed(error.localizedDescription)
            handle(userError)
            self.currentUser = nil
            self.isRefreshing = false
        }
    }
    
    // MARK: - Restore from iCloud
    /// Attempts to discover/download the User from the CloudKit-backed store.
    /// CloudKit sync is asynchronous; we poll for a short window to allow sync to complete.
    func restoreFromCloud(timeout: TimeInterval = 3, pollInterval: TimeInterval = 1.0) async {
        guard currentUser == nil else { return }
        isRestoringFromCloud = true
        defer { isRestoringFromCloud = false }

        // Immediate refresh attempt
        await refresh()
        if currentUser != nil { return }

        // Poll with a timeout to allow CloudKit to bring down records
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline, currentUser == nil {
            if Task.isCancelled { return }
            // Sleep for the poll interval
            try? await Task.sleep(nanoseconds: UInt64(pollInterval * 1_000_000_000))
            // Try another refresh
            await refresh()
            if currentUser != nil {
                print("Got user from iCloud!")
                break
            }
        }
        // If still nil after timeout, surface a timeout error for diagnostics
        if currentUser == nil {
            handle(UserError.fetchFailed("iCloud restore timed out"))
        }
    }
    
    // MARK: - Create or Replace
    func createOrReplace(
        newUser: User
    ) {
        do {
            // Delete any existing user
            if let u = currentUser {
                context.delete(u)
            }
            context.insert(newUser)
            try context.save()
            Task { await refresh() }
            print("User Saved!")
        } catch {
            handle(UserError.updateFailed(error.localizedDescription))
        }
    }
    
    // MARK: - Update
    func update(_ mutate: (User) -> Void) {
        guard let u = currentUser else {
            handle(UserError.fetchFailed("User not found"))
            return
        }
        mutate(u)
        do {
            try context.save()
            Task { await refresh() }
        } catch {
            handle(UserError.updateFailed("Failed to update user info"))
        }
    }
    
    // MARK: - Delete
    func deleteUser() {
        guard let user = currentUser else {
            handle(UserError.fetchFailed("User not found"))
            return
        }
        do {
            context.delete(user)
            try context.save()
            Task { await refresh() }
        } catch {
            handle(UserError.deletionFailed(error.localizedDescription))
        }
    }
    
    // MARK: - Error Handling
    private func handle(_ error: UserError) {
        print("Error: \(error.errorDescription ?? "Unknown UserManager error")")
    }
}

