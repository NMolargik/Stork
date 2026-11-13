//
//  ReviewPromptPolicy.swift
//  StorkCore
//
//  When to ask for an App Store rating: only after a moment the user chose and finished,
//  never while logging a delivery, never on a loss or remembrance screen, and never on the
//  milestone celebration that follows a log. At most once per app version and never within
//  3 days of first launch. Persists behind `KeyValueStoring`, prompts through the
//  `ReviewRequesting` seam, and takes an injected clock, so every rule is testable.
//

import Foundation

@MainActor
public final class ReviewPromptPolicy {
    /// The only moments that may prompt. Delivery logging, loss and remembrance flows, and
    /// the post-log milestone celebration are deliberately absent.
    public enum Moment: Equatable, Sendable {
        case milestoneCardShared
        case yearWrapShared
        case yearWrapViewedToEnd
        case csvImported
        case exportShared
    }

    public static let lastPromptedVersionKey = "ReviewPrompt.lastPromptedVersion"
    public static let firstLaunchKey = "ReviewPrompt.firstLaunchDate"
    /// Legacy Bool flags, read once to migrate so nobody already prompted is asked again.
    public static let legacyKeys = [
        "ReviewPrompt.hasPromptedAfterMilestoneShare",
        "DeliveryManager.hasPromptedForFifthReview"
    ]
    public static let minimumDaysSinceFirstLaunch = 3

    private let storage: any KeyValueStoring
    private let requester: (any ReviewRequesting)?
    private let appVersion: String
    private let now: () -> Date

    public init(
        storage: any KeyValueStoring,
        requester: (any ReviewRequesting)?,
        appVersion: String,
        now: @escaping () -> Date = Date.init
    ) {
        self.storage = storage
        self.requester = requester
        self.appVersion = appVersion
        self.now = now
        recordLaunch()
    }

    /// Stamps the first-launch date once and migrates the legacy flags.
    private func recordLaunch() {
        if storage.string(forKey: Self.firstLaunchKey) == nil {
            storage.set(Self.format(now()), forKey: Self.firstLaunchKey)
        }
        if storage.string(forKey: Self.lastPromptedVersionKey) == nil,
           Self.legacyKeys.contains(where: { storage.bool(forKey: $0) }) {
            storage.set(appVersion, forKey: Self.lastPromptedVersionKey)
        }
    }

    /// Call when one of the eligible moments completes. Prompts only if every rule allows.
    public func record(_ moment: Moment) {
        guard let requester else { return }
        guard storage.string(forKey: Self.lastPromptedVersionKey) != appVersion else { return }
        guard let stamp = storage.string(forKey: Self.firstLaunchKey), let first = Self.parse(stamp) else { return }
        guard now().timeIntervalSince(first) >= Double(Self.minimumDaysSinceFirstLaunch) * 86_400 else { return }
        storage.set(appVersion, forKey: Self.lastPromptedVersionKey)
        requester.requestReview()
    }

    private static func format(_ date: Date) -> String { String(date.timeIntervalSince1970) }
    private static func parse(_ string: String) -> Date? { TimeInterval(string).map(Date.init(timeIntervalSince1970:)) }
}
