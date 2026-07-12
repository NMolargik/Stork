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

    /// Guards against redundant work when several entry points (MainView, the step pill, and
    /// the tab-bar accessory re-instantiating its content) all kick off setup at launch.
    @ObservationIgnored private var isRequestingAuthorization = false
    @ObservationIgnored private var isObserving = false

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
        // Already granted, or a request is already in flight — nothing to redo. The synchronous
        // guard-and-set runs before the first `await`, so on the serial MainActor concurrent
        // launch callers collapse to a single real request.
        if isAuthorized { return }
        guard !isRequestingAuthorization else { return }
        isRequestingAuthorization = true
        defer {
            isRequestingAuthorization = false
            hasRequestedAuthorization = true
        }

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
            let initial = try? await reader.todayStepCount()
            todayStepCount = initial ?? 0
            lastError = nil
            Log.health.info(
                "Authorization request completed. healthDataAvailable=\(self.reader.isHealthDataAvailable, privacy: .public), initialTodaySteps=\(initial.map(String.init) ?? "nil (denied or no samples)", privacy: .public)"
            )
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
        guard !isObserving else { return }
        isObserving = true
        refreshTodayStepCount()
        reader.startObservingStepChanges { [weak self] in
            Task { @MainActor in self?.refreshTodayStepCount() }
        }
    }

    public func stopObserving() {
        isObserving = false
        reader.stopObserving()
    }

    // MARK: - Fetching

    public func fetchWeeklyStepCounts() async {
        guard isAuthorized else { return }
        do {
            weeklyStepCounts = try await reader.dailyStepCounts(days: 7)
            let total = weeklyStepCounts.reduce(0) { $0 + $1.steps }
            Log.health.info("Weekly step query returned \(self.weeklyStepCounts.count, privacy: .public) days, total=\(total, privacy: .public) steps.")
        } catch {
            lastError = error
            Log.health.error("Weekly step query failed: \(error.localizedDescription)")
        }
    }

    private func refreshTodayStepCount() {
        Task {
            do {
                let steps = try await reader.todayStepCount()
                Log.health.info("Today step query returned \(steps.map(String.init) ?? "nil (denied or no samples)", privacy: .public).")
                if let steps { todayStepCount = steps }
            } catch {
                lastError = error
                Log.health.error("Step query failed: \(error.localizedDescription)")
            }
        }
    }
}
#endif
