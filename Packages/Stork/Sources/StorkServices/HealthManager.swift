//
//  HealthManager.swift
//  StorkServices
//
//  Observable step-count state for the UI, shared by the iOS app and the watch app. All
//  HealthKit specifics live behind `StepCountReading`. Compiled only where HealthKit
//  exists (iOS/watchOS).
//

#if canImport(HealthKit) && !os(visionOS)
import Foundation
import Observation
import os
import StorkCore

@MainActor
@Observable
public final class HealthManager {

    @ObservationIgnored private let reader: any StepCountReading

    public private(set) var isAuthorized: Bool = false
    public private(set) var hasRequestedAuthorization: Bool = false
    public private(set) var lastError: Error?

    /// Live-updating total steps for the current calendar day (midnight -> now).
    public private(set) var todayStepCount: Int = 0

    /// Daily step counts for the last 7 days (oldest first).
    public private(set) var weeklyStepCounts: [(date: Date, steps: Int)] = []

    public init(reader: any StepCountReading = HealthKitStepReader()) {
        self.reader = reader
    }

    /// Whether step tracking can ever work here. False on Mac/Vision ("Designed for
    /// iPad"): no pedometer, so all step UI should be hidden.
    public var isStepTrackingSupported: Bool {
        #if os(iOS)
        if ProcessInfo.processInfo.isiOSAppOnMac { return false }
        #endif
        return reader.isHealthDataAvailable
    }

    // MARK: - Authorization

    public func requestAuthorization() async {
        defer { hasRequestedAuthorization = true }

        guard reader.isHealthDataAvailable else {
            isAuthorized = false
            lastError = nil
            Log.health.info("Health data not available on this device.")
            return
        }

        do {
            try await reader.requestReadAuthorization()
            // HealthKit hides read-permission state, so a non-throwing request is the only
            // signal — treat it as granted. A nil/zero count means "no samples" (iPad), not denied.
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

    public func startObservingStepCount() {
        guard isAuthorized else {
            Log.health.info("startObservingStepCount called without authorization.")
            return
        }
        refreshTodayStepCount()
        reader.startObservingStepChanges { [weak self] in
            Task { @MainActor in self?.refreshTodayStepCount() }
        }
    }

    public func stopObserving() {
        reader.stopObserving()
    }

    // MARK: - Fetching

    public func fetchWeeklyStepCounts() async {
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
