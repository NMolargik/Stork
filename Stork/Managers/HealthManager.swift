//
//  HealthManager.swift
//  Stork
//

#if !os(visionOS)
import Foundation
import Observation
import os

/// Observable step-count state for the UI, shared by the iOS app and the
/// watch app. All HealthKit specifics live behind `StepCountReading`.
@MainActor
@Observable
final class HealthManager {

    @ObservationIgnored private let reader: StepCountReading

    private(set) var isAuthorized: Bool = false
    private(set) var hasRequestedAuthorization: Bool = false
    private(set) var lastError: Error?

    /// Live-updating total steps for the current calendar day (midnight -> now).
    private(set) var todayStepCount: Int = 0

    /// Daily step counts for the last 7 days (oldest first).
    private(set) var weeklyStepCounts: [(date: Date, steps: Int)] = []

    init(reader: StepCountReading = HealthKitStepReader()) {
        self.reader = reader
    }

    /// Whether step tracking can ever work in this environment. False when
    /// the iPad app runs on a Mac or Apple Vision Pro ("Designed for iPad"):
    /// there is no pedometer there, so all step UI should be hidden.
    /// (Macs can report HealthKit as available via iPhone-synced data, so
    /// the explicit app-on-Mac check comes first.)
    var isStepTrackingSupported: Bool {
        #if os(iOS)
        if ProcessInfo.processInfo.isiOSAppOnMac { return false }
        #endif
        return reader.isHealthDataAvailable
    }

    // MARK: - Authorization

    func requestAuthorization() async {
        defer { hasRequestedAuthorization = true }

        guard reader.isHealthDataAvailable else {
            isAuthorized = false
            lastError = nil
            Log.health.info("Health data not available on this device.")
            return
        }

        do {
            try await reader.requestReadAuthorization()
            // HealthKit deliberately hides read-permission state, so a
            // non-throwing request is the only authorization signal we get —
            // treat it as granted. A nil/zero step count means "no samples
            // yet" (e.g. iPad, which has no pedometer), NOT denied. Conflating
            // the two made onboarding falsely report "Access Denied" right
            // after the user approved the prompt.
            isAuthorized = true
            todayStepCount = (try? await reader.todayStepCount()) ?? 0
            lastError = nil
        } catch {
            isAuthorized = false
            lastError = error
            Log.health.error("Authorization failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Observing

    /// Start listening for step count updates for the current day.
    /// Call after `requestAuthorization()` has succeeded.
    func startObservingStepCount() {
        guard isAuthorized else {
            Log.health.info("startObservingStepCount called without authorization.")
            return
        }

        refreshTodayStepCount()

        reader.startObservingStepChanges { [weak self] in
            Task { @MainActor in
                self?.refreshTodayStepCount()
            }
        }
    }

    func stopObserving() {
        reader.stopObserving()
    }

    // MARK: - Fetching

    func fetchWeeklyStepCounts() async {
        guard isAuthorized else { return }
        do {
            weeklyStepCounts = try await reader.dailyStepCounts(days: 7)
        } catch {
            lastError = error
            Log.health.error("Weekly step query failed: \(error.localizedDescription)")
        }
    }

    private func refreshTodayStepCount() {
        Task {
            do {
                if let steps = try await reader.todayStepCount() {
                    todayStepCount = steps
                }
            } catch {
                lastError = error
                Log.health.error("Step query failed: \(error.localizedDescription)")
            }
        }
    }
}
#endif
