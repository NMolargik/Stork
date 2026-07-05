//
//  DeliveryChangeCenter.swift
//  StorkCore
//
//  Multicast change signal for the delivery store. The repository notifies after every
//  successful mutation and `CloudSyncManager` notifies on CloudKit imports, so any screen
//  can observe one stream instead of the composition root juggling callbacks. Replaces
//  the old single-subscriber `onRemoteDeliveriesChange` closure (last writer won).
//

import Foundation

@MainActor
public final class DeliveryChangeCenter {

    private var continuations: [UUID: AsyncStream<Void>.Continuation] = [:]

    public init() {}

    /// A stream that yields whenever the delivery store changes — local writes and
    /// CloudKit imports alike. Terminates automatically when the observing task ends.
    public func changes() -> AsyncStream<Void> {
        let (stream, continuation) = AsyncStream<Void>.makeStream()
        let id = UUID()
        continuations[id] = continuation
        continuation.onTermination = { [weak self] _ in
            Task { @MainActor in self?.continuations[id] = nil }
        }
        return stream
    }

    /// Notifies every active observer.
    public func notify() {
        for continuation in continuations.values {
            continuation.yield(())
        }
    }
}

// MARK: - Use case

/// Observes delivery-store changes as an `AsyncStream`.
@MainActor
public protocol ObserveDeliveryChanges {
    func callAsFunction() -> AsyncStream<Void>
}

public struct ObserveDeliveryChangesUseCase: ObserveDeliveryChanges {
    private let center: DeliveryChangeCenter
    public init(center: DeliveryChangeCenter) { self.center = center }
    public func callAsFunction() -> AsyncStream<Void> {
        center.changes()
    }
}
