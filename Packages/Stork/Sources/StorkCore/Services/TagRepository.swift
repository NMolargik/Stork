//
//  TagRepository.swift
//  StorkCore
//
//  The tag data boundary. `DefaultTagRepository` in `StorkData` owns the SwiftData
//  context. Single-verb use-cases wrap each operation so view models depend on one verb;
//  failures are typed (`throws(PersistenceError)`).
//

import Foundation

@MainActor
public protocol TagRepository: AnyObject {
    /// All tags, alphabetically by name.
    func tags() throws(PersistenceError) -> [DeliveryTag]

    /// Inserts a new tag and persists.
    func add(_ tag: DeliveryTag) throws(PersistenceError)

    /// Persists edits to an existing tag.
    func update(_ tag: DeliveryTag) throws(PersistenceError)

    /// Deletes a tag and persists.
    func delete(_ tag: DeliveryTag) throws(PersistenceError)
}

// MARK: - Use cases

@MainActor
public protocol LoadTags {
    func callAsFunction() throws(PersistenceError) -> [DeliveryTag]
}

public struct LoadTagsUseCase: LoadTags {
    private let repository: any TagRepository
    public init(repository: any TagRepository) { self.repository = repository }
    public func callAsFunction() throws(PersistenceError) -> [DeliveryTag] {
        try repository.tags()
    }
}

@MainActor
public protocol SaveTag {
    /// Inserts `tag` when `isNew`, otherwise persists edits.
    func callAsFunction(_ tag: DeliveryTag, isNew: Bool) throws(PersistenceError)
}

public struct SaveTagUseCase: SaveTag {
    private let repository: any TagRepository
    public init(repository: any TagRepository) { self.repository = repository }
    public func callAsFunction(_ tag: DeliveryTag, isNew: Bool) throws(PersistenceError) {
        if isNew {
            try repository.add(tag)
        } else {
            try repository.update(tag)
        }
    }
}

@MainActor
public protocol DeleteTag {
    func callAsFunction(_ tag: DeliveryTag) throws(PersistenceError)
}

public struct DeleteTagUseCase: DeleteTag {
    private let repository: any TagRepository
    public init(repository: any TagRepository) { self.repository = repository }
    public func callAsFunction(_ tag: DeliveryTag) throws(PersistenceError) {
        try repository.delete(tag)
    }
}
