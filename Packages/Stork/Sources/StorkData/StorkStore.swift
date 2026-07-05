//
//  StorkStore.swift
//  StorkData
//
//  Builds the SwiftData `ModelContainer`. Production uses the CloudKit private database
//  for background iCloud sync; tests and previews use an in-memory store.
//

import Foundation
import SwiftData
import StorkCore

public enum StorkStore {
    /// The CloudKit container backing the private database. Unchanged from the original
    /// app so existing users' data continues to sync.
    public static let cloudKitContainerID = "iCloud.com.molargiksoftware.Stork"

    /// The model types persisted by the app.
    public static let models: [any PersistentModel.Type] = [Delivery.self, Baby.self, DeliveryTag.self]

    /// Builds the shared container. Pass `inMemory: true` for tests/previews;
    /// `inAppGroup: true` on the watch, whose store lives in the app-group container so
    /// its widget extension can read it.
    public static func makeContainer(inMemory: Bool = false, inAppGroup: Bool = false) throws -> ModelContainer {
        let configuration: ModelConfiguration
        if inMemory {
            configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        } else if inAppGroup {
            configuration = ModelConfiguration(
                groupContainer: .identifier(AppGroup.id),
                cloudKitDatabase: .private(cloudKitContainerID)
            )
        } else {
            configuration = ModelConfiguration(cloudKitDatabase: .private(cloudKitContainerID))
        }

        return try ModelContainer(
            for: Delivery.self, Baby.self, DeliveryTag.self,
            configurations: configuration
        )
    }
}
