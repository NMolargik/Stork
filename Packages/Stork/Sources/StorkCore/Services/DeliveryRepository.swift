//
//  DeliveryRepository.swift
//  StorkCore
//
//  The delivery data boundary. `DeliveryRepository` is the one place the rest of the app
//  reads and writes deliveries; the concrete `DefaultDeliveryRepository` in `StorkData`
//  owns the SwiftData `ModelContext` and fires the save side effects (widget refresh,
//  app-group fallback counts, Spotlight reindex, milestone detection, review prompt).
//
//  Each operation also gets a thin single-verb use-case wrapper so view models depend on
//  one verb rather than the whole repository — mirroring SCOUT's repository/use-case split.
//  Failures are typed (`throws(PersistenceError)`) so callers catch a concrete error.
//  Everything is MainActor-isolated because it touches the `@Model` types.
//

import Foundation

/// Career totals as a value type, so use-cases and tests can compare them directly.
public struct CareerTotals: Equatable, Sendable {
    public let deliveries: Int
    public let babies: Int

    public init(deliveries: Int, babies: Int) {
        self.deliveries = deliveries
        self.babies = babies
    }
}

@MainActor
public protocol DeliveryRepository: AnyObject {
    /// All deliveries, newest first.
    func deliveries() throws(PersistenceError) -> [Delivery]

    /// Inserts a brand-new delivery and persists, running save side effects
    /// (widget refresh, app-group counts, Spotlight reindex, review prompt).
    /// Returns a newly crossed career milestone to celebrate, if any.
    @discardableResult
    func add(_ delivery: Delivery) throws(PersistenceError) -> MilestoneCelebration?

    /// Persists edits to an already-inserted delivery, running save side effects.
    func update(_ delivery: Delivery) throws(PersistenceError)

    /// Deletes a delivery (cascading its babies) and persists.
    func delete(_ delivery: Delivery) throws(PersistenceError)

    /// Deletes every delivery in one transaction, running save side effects once.
    func deleteAll() throws(PersistenceError)

    /// Career totals queried from the store (not the possibly-stale view cache).
    func careerTotals() -> CareerTotals
}

// MARK: - Use cases

/// Loads all deliveries, newest first.
@MainActor
public protocol LoadDeliveries {
    func callAsFunction() throws(PersistenceError) -> [Delivery]
}

public struct LoadDeliveriesUseCase: LoadDeliveries {
    private let repository: any DeliveryRepository
    public init(repository: any DeliveryRepository) { self.repository = repository }
    public func callAsFunction() throws(PersistenceError) -> [Delivery] {
        try repository.deliveries()
    }
}

/// Logs a brand-new delivery, returning a milestone to celebrate if one was crossed.
@MainActor
public protocol LogDelivery {
    @discardableResult
    func callAsFunction(_ delivery: Delivery) throws(PersistenceError) -> MilestoneCelebration?
}

public struct LogDeliveryUseCase: LogDelivery {
    private let repository: any DeliveryRepository
    public init(repository: any DeliveryRepository) { self.repository = repository }
    @discardableResult
    public func callAsFunction(_ delivery: Delivery) throws(PersistenceError) -> MilestoneCelebration? {
        try repository.add(delivery)
    }
}

/// Saves edits to an existing delivery.
@MainActor
public protocol UpdateDelivery {
    func callAsFunction(_ delivery: Delivery) throws(PersistenceError)
}

public struct UpdateDeliveryUseCase: UpdateDelivery {
    private let repository: any DeliveryRepository
    public init(repository: any DeliveryRepository) { self.repository = repository }
    public func callAsFunction(_ delivery: Delivery) throws(PersistenceError) {
        try repository.update(delivery)
    }
}

/// Deletes a delivery.
@MainActor
public protocol DeleteDelivery {
    func callAsFunction(_ delivery: Delivery) throws(PersistenceError)
}

public struct DeleteDeliveryUseCase: DeleteDelivery {
    private let repository: any DeliveryRepository
    public init(repository: any DeliveryRepository) { self.repository = repository }
    public func callAsFunction(_ delivery: Delivery) throws(PersistenceError) {
        try repository.delete(delivery)
    }
}

/// Deletes every delivery in one transaction (Settings' "Delete All").
@MainActor
public protocol DeleteAllDeliveries {
    func callAsFunction() throws(PersistenceError)
}

public struct DeleteAllDeliveriesUseCase: DeleteAllDeliveries {
    private let repository: any DeliveryRepository
    public init(repository: any DeliveryRepository) { self.repository = repository }
    public func callAsFunction() throws(PersistenceError) {
        try repository.deleteAll()
    }
}

/// Reads career totals straight from the store (Siri stats, widgets, milestones).
@MainActor
public protocol LoadCareerTotals {
    func callAsFunction() -> CareerTotals
}

public struct LoadCareerTotalsUseCase: LoadCareerTotals {
    private let repository: any DeliveryRepository
    public init(repository: any DeliveryRepository) { self.repository = repository }
    public func callAsFunction() -> CareerTotals {
        repository.careerTotals()
    }
}
