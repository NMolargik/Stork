//
//  StepCountReading.swift
//  StorkServices
//
//  Seam over HealthKit step queries. `HealthManager` orchestrates state on top of this;
//  tests substitute a fake reader. Compiled only where HealthKit exists (iOS/watchOS).
//

#if canImport(HealthKit) && !os(visionOS)
import Foundation
import HealthKit

public protocol StepCountReading: AnyObject {
    var isHealthDataAvailable: Bool { get }
    func requestReadAuthorization() async throws
    /// Cumulative steps from midnight to now, or nil when read access is denied.
    func todayStepCount() async throws -> Int?
    /// Daily totals for the last `days` days including today, oldest first.
    func dailyStepCounts(days: Int) async throws -> [(date: Date, steps: Int)]
    /// Invokes `handler` whenever HealthKit reports step samples changed.
    func startObservingStepChanges(_ handler: @escaping @Sendable () -> Void)
    func stopObserving()
}

/// Production reader backed by `HKHealthStore`.
public final class HealthKitStepReader: StepCountReading {

    private let healthStore = HKHealthStore()
    private let stepType = HKQuantityType(.stepCount)
    private var observerQuery: HKObserverQuery?

    public init() {}

    public var isHealthDataAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    public func requestReadAuthorization() async throws {
        try await healthStore.requestAuthorization(toShare: [], read: [stepType])
    }

    public func todayStepCount() async throws -> Int? {
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: [])

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: stepType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { @Sendable _, stats, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if let quantity = stats?.sumQuantity() {
                    continuation.resume(returning: Int(quantity.doubleValue(for: .count())))
                } else {
                    // No samples is "no data" (e.g. iPad has no pedometer), NOT denial.
                    continuation.resume(returning: nil)
                }
            }
            healthStore.execute(query)
        }
    }

    public func dailyStepCounts(days: Int) async throws -> [(date: Date, steps: Int)] {
        let calendar = Calendar.current
        let now = Date()
        let startOfToday = calendar.startOfDay(for: now)
        guard let rangeStart = calendar.date(byAdding: .day, value: -(days - 1), to: startOfToday) else {
            return []
        }

        let predicate = HKQuery.predicateForSamples(withStart: rangeStart, end: now, options: [])

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsCollectionQuery(
                quantityType: stepType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum,
                anchorDate: rangeStart,
                intervalComponents: DateComponents(day: 1)
            )

            query.initialResultsHandler = { @Sendable _, results, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                var daily: [(date: Date, steps: Int)] = []
                results?.enumerateStatistics(from: rangeStart, to: now) { stats, _ in
                    let steps = stats.sumQuantity()?.doubleValue(for: .count()) ?? 0
                    daily.append((date: stats.startDate, steps: Int(steps)))
                }
                continuation.resume(returning: daily)
            }
            healthStore.execute(query)
        }
    }

    public func startObservingStepChanges(_ handler: @escaping @Sendable () -> Void) {
        stopObserving()
        let observer = HKObserverQuery(sampleType: stepType, predicate: nil) { @Sendable _, _, error in
            guard error == nil else { return }
            handler()
        }
        observerQuery = observer
        healthStore.execute(observer)
    }

    public func stopObserving() {
        if let observerQuery {
            healthStore.stop(observerQuery)
        }
        observerQuery = nil
    }
}
#endif
