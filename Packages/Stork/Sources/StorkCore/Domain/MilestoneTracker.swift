//
//  MilestoneTracker.swift
//  StorkCore
//
//  Career-milestone detection with persistence behind the `KeyValueStoring` seam.
//  Baby milestones outrank delivery milestones when both cross at once.
//

import Foundation

/// A career milestone that should be celebrated.
public struct MilestoneCelebration: Equatable, Sendable {
    public let count: Int
    public let type: MilestoneType

    public enum MilestoneType: String, Sendable {
        case babies
        case deliveries
    }

    public init(count: Int, type: MilestoneType) {
        self.count = count
        self.type = type
    }
}

/// Decides when a career milestone has been crossed and remembers which milestones were
/// already celebrated so users don't re-see them.
public final class MilestoneTracker {

    public static let babyMilestones: [Int] = [100, 250, 500, 1000, 2500, 5000, 10000]
    public static let deliveryMilestones: [Int] = [50, 100, 250, 500, 1000, 2500, 5000]

    private let storage: KeyValueStoring
    private let storageKey: String

    /// `storageKey` defaults to the key historically written by the app so existing
    /// users don't re-see past celebrations.
    public init(
        storage: KeyValueStoring,
        storageKey: String = "DeliveryManager.celebratedMilestones"
    ) {
        self.storage = storage
        self.storageKey = storageKey
    }

    /// Returns the highest newly crossed milestone, marking it celebrated — or `nil`
    /// when no uncelebrated milestone has been reached.
    public func checkForNewMilestone(totalBabies: Int, totalDeliveries: Int) -> MilestoneCelebration? {
        var celebrated = celebratedMilestones

        for milestone in Self.babyMilestones.reversed() where totalBabies >= milestone {
            let key = "babies-\(milestone)"
            if !celebrated.contains(key) {
                celebrated.insert(key)
                celebratedMilestones = celebrated
                return MilestoneCelebration(count: milestone, type: .babies)
            }
        }

        for milestone in Self.deliveryMilestones.reversed() where totalDeliveries >= milestone {
            let key = "deliveries-\(milestone)"
            if !celebrated.contains(key) {
                celebrated.insert(key)
                celebratedMilestones = celebrated
                return MilestoneCelebration(count: milestone, type: .deliveries)
            }
        }

        return nil
    }

    private var celebratedMilestones: Set<String> {
        get { Set(storage.stringArray(forKey: storageKey) ?? []) }
        set { storage.set(Array(newValue), forKey: storageKey) }
    }
}
