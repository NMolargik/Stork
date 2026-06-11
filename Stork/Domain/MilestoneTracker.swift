//
//  MilestoneTracker.swift
//  Stork
//

import Foundation

/// A career milestone that should be celebrated.
struct MilestoneCelebration: Equatable {
    let count: Int
    let type: MilestoneType

    enum MilestoneType: String {
        case babies
        case deliveries
    }
}

/// Decides when a career milestone has been crossed and remembers which
/// milestones were already celebrated.
///
/// Baby milestones outrank delivery milestones when both cross at once.
final class MilestoneTracker {

    static let babyMilestones: [Int] = [100, 250, 500, 1000, 2500, 5000, 10000]
    static let deliveryMilestones: [Int] = [50, 100, 250, 500, 1000, 2500, 5000]

    private let storage: KeyValueStoring
    private let storageKey: String

    /// `storageKey` defaults to the key historically written by DeliveryManager
    /// so existing users don't re-see past celebrations.
    init(
        storage: KeyValueStoring = UserDefaults.standard,
        storageKey: String = "DeliveryManager.celebratedMilestones"
    ) {
        self.storage = storage
        self.storageKey = storageKey
    }

    /// Returns the highest newly crossed milestone, marking it celebrated —
    /// or nil when no uncelebrated milestone has been reached.
    func checkForNewMilestone(totalBabies: Int, totalDeliveries: Int) -> MilestoneCelebration? {
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
