//
//  HealthManager.swift
//  Stork
//
//  Created by Nick Molargik on 10/1/25.
//

#if !os(visionOS)
import Foundation
import HealthKit

@MainActor
@Observable
final class HealthManager {

    // MARK: - HealthKit
    private let healthStore = HKHealthStore()
    private let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!

    // Keep references so we can stop them later
    private var observerQuery: HKObserverQuery?
    private var statisticsQuery: HKStatisticsQuery?

    // MARK: - Public state
    private(set) var isAuthorized: Bool = false
    private(set) var hasRequestedAuthorization: Bool = false
    private(set) var lastError: Error?

    /// Live-updating total steps for the current calendar day (midnight -> now).
    private(set) var todayStepCount: Int = 0

    /// Daily step counts for the last 7 days (oldest first). Each entry is (date, steps).
    private(set) var weeklyStepCounts: [(date: Date, steps: Int)] = []

    // MARK: - Authorization
    func requestAuthorization() async {
        defer { self.hasRequestedAuthorization = true }

        guard HKHealthStore.isHealthDataAvailable() else {
            self.isAuthorized = false
            self.lastError = nil
            print("[HealthManager] Health data not available on this device.")
            return
        }

        let toRead: Set<HKObjectType> = [stepType]

        do {
            try await healthStore.requestAuthorization(toShare: [], read: toRead)
            #if os(visionOS)
            // visionOS has no built-in pedometer, so the probe (which checks for
            // existing step data) falsely reports "no read access" when there's
            // simply no data source. Assume authorized if the request didn't throw.
            self.isAuthorized = true
            #else
            // Probe read access by attempting a statistics query. On iOS/iPadOS
            // the built-in pedometer virtually guarantees step samples exist.
            await probeReadAccessForSteps()
            #endif
            self.lastError = nil
        } catch {
            self.isAuthorized = false
            self.lastError = error
            print("[HealthManager] Authorization failed: \(error)")
        }
    }

    // MARK: - Observing step count

    /// Start listening for step count updates for the current day.
    /// Call after `requestAuthorization()` has succeeded.
    func startObservingStepCount() {
        guard isAuthorized else {
            print("[HealthManager] startObservingStepCount called without authorization.")
            return
        }

        // Initial fetch
        fetchTodayStepCount()

        // Observe changes to step samples
        let observer = HKObserverQuery(sampleType: stepType, predicate: nil) { [weak self] _, _, error in
            guard let self else { return }
            if let error {
                Task { @MainActor in self.lastError = error }
                print("[HealthManager] Observer error: \(error)")
                return
            }
            // Fetch updated value whenever HealthKit notifies us of changes
            Task { @MainActor in
                self.fetchTodayStepCount()
            }
        }
        self.observerQuery = observer
        healthStore.execute(observer)
    }

    /// Stop listening to step updates.
    func stopObserving() {
        if let q = observerQuery { healthStore.stop(q) }
        if let q = statisticsQuery { healthStore.stop(q) }
        observerQuery = nil
        statisticsQuery = nil
    }

    // MARK: - Fetch helpers

    /// Runs a one-shot statistics query to determine if we have read access to step data.
    /// Updates `isAuthorized` accordingly and, if possible, seeds `todayStepCount`.
    private func probeReadAccessForSteps() async {
        let calendar = Calendar.current
        let now = Date()
        let startOfDay = calendar.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: [])

        await withCheckedContinuation { (cont: CheckedContinuation<Void, Never>) in
            let query = HKStatisticsQuery(
                quantityType: stepType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { [weak self] _, stats, error in
                guard let self else { cont.resume(); return }

                Task { @MainActor in
                    if let error {
                        // Treat errors as not authorized for our purposes
                        self.lastError = error
                        self.isAuthorized = false
                        print("[HealthManager] Probe error: \(error)")
                    } else if let quantity = stats?.sumQuantity() {
                        // If we can read a quantity (even if value is 0), we have read access.
                        self.isAuthorized = true
                        let value = quantity.doubleValue(for: .count())
                        self.todayStepCount = Int(value)
                    } else {
                        // No quantity returned implies no read access.
                        self.isAuthorized = false
                        self.todayStepCount = 0
                    }
                    cont.resume()
                }
            }

            // Execute without storing; this is a one-shot probe.
            self.healthStore.execute(query)
        }
    }

    /// Fetch daily step totals for the last 7 days and update `weeklyStepCounts`.
    func fetchWeeklyStepCounts() async {
        guard isAuthorized else { return }

        let calendar = Calendar.current
        let now = Date()
        let startOfToday = calendar.startOfDay(for: now)
        guard let sevenDaysAgo = calendar.date(byAdding: .day, value: -6, to: startOfToday) else { return }

        let predicate = HKQuery.predicateForSamples(withStart: sevenDaysAgo, end: now, options: [])

        await withCheckedContinuation { (cont: CheckedContinuation<Void, Never>) in
            let query = HKStatisticsCollectionQuery(
                quantityType: stepType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum,
                anchorDate: sevenDaysAgo,
                intervalComponents: DateComponents(day: 1)
            )

            query.initialResultsHandler = { [weak self] _, results, error in
                guard let self else { cont.resume(); return }

                Task { @MainActor in
                    defer { cont.resume() }
                    if let error {
                        self.lastError = error
                        print("[HealthManager] Weekly query error: \(error)")
                        return
                    }
                    guard let results else { return }

                    var daily: [(date: Date, steps: Int)] = []
                    results.enumerateStatistics(from: sevenDaysAgo, to: now) { stats, _ in
                        let steps = stats.sumQuantity()?.doubleValue(for: .count()) ?? 0
                        daily.append((date: stats.startDate, steps: Int(steps)))
                    }
                    self.weeklyStepCounts = daily
                }
            }

            self.healthStore.execute(query)
        }
    }

    /// Fetch the cumulative step count from midnight to now and update `todayStepCount`.
    private func fetchTodayStepCount() {
        let calendar = Calendar.current
        let now = Date()
        let startOfDay = calendar.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: [])

        let statsQuery = HKStatisticsQuery(
            quantityType: stepType,
            quantitySamplePredicate: predicate,
            options: .cumulativeSum
        ) { [weak self] _, stats, error in
            guard let self else { return }
            if let error {
                Task { @MainActor in self.lastError = error }
                print("[HealthManager] Statistics query error: \(error)")
                return
            }

            let quantity = stats?.sumQuantity()
            let value = quantity?.doubleValue(for: .count()) ?? 0
            Task { @MainActor in
                self.todayStepCount = Int(value)
            }
        }
        self.statisticsQuery = statsQuery
        healthStore.execute(statsQuery)
    }
}
#endif

