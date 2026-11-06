//
//  MilestoneShareReviewPolicy.swift
//  StorkCore
//
//  Asks for an App Store review once, the first time a career-milestone share card is
//  shared — a moment the user is proud of. Persists behind `KeyValueStoring` so the prompt
//  can never repeat; prompts through the `ReviewRequesting` seam so it is testable.
//  (The "5th delivery" prompt lives in the repository; this is the second and last.)
//

import Foundation

@MainActor
public final class MilestoneShareReviewPolicy {
    public static let defaultStorageKey = "ReviewPrompt.hasPromptedAfterMilestoneShare"

    private let storage: any KeyValueStoring
    private let requester: (any ReviewRequesting)?
    private let storageKey: String

    public init(storage: any KeyValueStoring, requester: (any ReviewRequesting)?, storageKey: String = MilestoneShareReviewPolicy.defaultStorageKey) {
        self.storage = storage
        self.requester = requester
        self.storageKey = storageKey
    }

    /// Call after a milestone card share completes. Prompts on the first call only.
    public func milestoneCardShared() {
        guard let requester, !storage.bool(forKey: storageKey) else { return }
        storage.set(true, forKey: storageKey)
        requester.requestReview()
    }
}
