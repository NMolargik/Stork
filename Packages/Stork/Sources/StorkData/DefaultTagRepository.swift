//
//  DefaultTagRepository.swift
//  StorkData
//
//  The SwiftData-backed `TagRepository`.
//

import Foundation
import SwiftData
import StorkCore
import os

@MainActor
public final class DefaultTagRepository: TagRepository {

    private let container: ModelContainer
    private let context: ModelContext

    public init(container: ModelContainer) {
        self.container = container
        self.context = container.mainContext
    }

    public func tags() throws(PersistenceError) -> [DeliveryTag] {
        do {
            return try context.fetch(
                FetchDescriptor<DeliveryTag>(sortBy: [SortDescriptor(\.name, order: .forward)])
            )
        } catch {
            Log.deliveries.error("Tag fetch failed: \(error.localizedDescription)")
            throw .fetchFailed(error.localizedDescription)
        }
    }

    public func add(_ tag: DeliveryTag) throws(PersistenceError) {
        context.insert(tag)
        try save()
    }

    public func update(_ tag: DeliveryTag) throws(PersistenceError) {
        try save()
    }

    public func delete(_ tag: DeliveryTag) throws(PersistenceError) {
        context.delete(tag)
        try save()
    }

    private func save() throws(PersistenceError) {
        do {
            try context.save()
        } catch {
            Log.deliveries.error("Tag save failed: \(error.localizedDescription)")
            throw .saveFailed(error.localizedDescription)
        }
    }
}
