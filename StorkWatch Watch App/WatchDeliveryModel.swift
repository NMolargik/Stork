//
//  WatchDeliveryModel.swift
//  StorkWatch Watch App
//
//  Drives the watch screens through use-cases — no `@Query`, no `modelContext`. Logging
//  goes through `LogDelivery`, so watch saves run the same side effects as iPhone saves
//  (app-group counts, complication reloads) and return real milestone detection.
//

import Foundation
import Observation
import StorkCore

@MainActor
@Observable
final class WatchDeliveryModel {

    private let loadDeliveriesUseCase: any LoadDeliveries
    private let logDeliveryUseCase: any LogDelivery

    private(set) var deliveries: [Delivery] = []
    private(set) var lastError: PersistenceError?

    init(loadDeliveries: any LoadDeliveries, logDelivery: any LogDelivery) {
        self.loadDeliveriesUseCase = loadDeliveries
        self.logDeliveryUseCase = logDelivery
    }

    func load() {
        do {
            deliveries = try loadDeliveriesUseCase()
            lastError = nil
        } catch {
            lastError = error   // keep stale data; stale beats blank
        }
    }

    /// Logs a quick entry, returning the saved delivery and any crossed career milestone.
    func log(
        boys: Int,
        girls: Int,
        losses: Int,
        method: DeliveryMethod
    ) throws(PersistenceError) -> (delivery: Delivery, milestone: MilestoneCelebration?) {
        var babies: [Baby] = []
        babies.append(contentsOf: (0..<boys).map { _ in Baby(sex: .male) })
        babies.append(contentsOf: (0..<girls).map { _ in Baby(sex: .female) })
        babies.append(contentsOf: (0..<losses).map { _ in Baby(sex: .loss) })

        let delivery = Delivery(
            date: .now,
            babies: babies,
            babyCount: babies.count,
            deliveryMethod: method,
            epiduralUsed: false,
            notes: "Added from Watch - may lack baby details."
        )
        for baby in babies { baby.delivery = delivery }

        let milestone = try logDeliveryUseCase(delivery)
        load()
        return (delivery, milestone)
    }
}
