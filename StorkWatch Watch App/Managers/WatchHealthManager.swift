//
//  WatchHealthManager.swift
//  StorkWatch Watch App
//
//  Created by Nick Molargik on 1/17/26.
//

import Foundation
import HealthKit

@MainActor
@Observable
final class WatchHealthManager {

    // MARK: - HealthKit
    private let healthStore = HKHealthStore()
    private let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!

    private var observerQuery: HKObserverQuery?
    private var statisticsQuery: HKStatisticsQuery?

    // MARK: - Public state
    private(set) var isAuthorized: Bool = false
    private(set) var lastError: Error?
    private(set) var todayStepCount: Int = 0

    // MARK: - Authorization
    func requestAuthorization() async {
        guard HKHealthStore.isHealthDataAvailable() else {
            self.isAuthorized = false
            self.lastError = nil
            return
        }

        let toRead: Set<HKObjectType> = [stepType]

        do {
            try await healthStore.requestAuthorization(toShare: [], read: toRead)
            await probeReadAccessForSteps()
            self.lastError = nil
        } catch {
            self.isAuthorized = false
            self.lastError = error
        }
    }

    // MARK: - Observing step count
    func startObservingStepCount() {
        guard isAuthorized else { return }

        fetchTodayStepCount()

        let observer = HKObserverQuery(sampleType: stepType, predicate: nil) { [weak self] _, _, error in
            guard let self else { return }
            if let error {
                Task { @MainActor in self.lastError = error }
                return
            }
            Task { @MainActor in
                self.fetchTodayStepCount()
            }
        }
        self.observerQuery = observer
        healthStore.execute(observer)
    }

    func stopObserving() {
        if let q = observerQuery { healthStore.stop(q) }
        if let q = statisticsQuery { healthStore.stop(q) }
        observerQuery = nil
        statisticsQuery = nil
    }

    // MARK: - Private helpers
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
                        self.lastError = error
                        self.isAuthorized = false
                    } else if let quantity = stats?.sumQuantity() {
                        self.isAuthorized = true
                        let value = quantity.doubleValue(for: .count())
                        self.todayStepCount = Int(value)
                    } else {
                        self.isAuthorized = false
                        self.todayStepCount = 0
                    }
                    cont.resume()
                }
            }

            self.healthStore.execute(query)
        }
    }

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
                return
            }

            let quantity = stats?.sumQuantity()
            let value = quantity?.doubleValue(for: .count()) ?? 0
            Task { @MainActor in
                self.isAuthorized = (quantity != nil)
                self.todayStepCount = Int(value)
            }
        }
        self.statisticsQuery = statsQuery
        healthStore.execute(statsQuery)
    }
}
