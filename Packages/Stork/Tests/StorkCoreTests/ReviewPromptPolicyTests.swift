//
//  ReviewPromptPolicyTests.swift
//  StorkCoreTests
//

import Foundation
import Testing
@testable import StorkCore

@Suite("ReviewPromptPolicy Tests")
@MainActor
struct ReviewPromptPolicyTests {
    private final class Clock { var date = Date(timeIntervalSince1970: 1_800_000_000) }

    private func make(version: String = "1.0", storage: FakeKeyValueStore = FakeKeyValueStore(), clock: Clock = Clock()) -> (ReviewPromptPolicy, FakeReviewRequester, FakeKeyValueStore, Clock) {
        let requester = FakeReviewRequester()
        let policy = ReviewPromptPolicy(storage: storage, requester: requester, appVersion: version, now: { clock.date })
        return (policy, requester, storage, clock)
    }

    private static let allMoments: [ReviewPromptPolicy.Moment] = [.milestoneCardShared, .yearWrapShared, .yearWrapViewedToEnd, .csvImported, .exportShared]

    @Test("Never within 3 days of first launch, then allowed")
    func threeDayGrace() {
        let (policy, requester, _, clock) = make()
        policy.record(.csvImported)
        clock.date.addTimeInterval(3 * 86_400 - 60)
        policy.record(.csvImported)
        #expect(requester.requestCount == 0)
        clock.date.addTimeInterval(60)
        policy.record(.csvImported)
        #expect(requester.requestCount == 1)
    }

    @Test("Every eligible moment can prompt")
    func eachMomentPrompts() {
        for moment in Self.allMoments {
            let (policy, requester, _, clock) = make()
            clock.date.addTimeInterval(4 * 86_400)
            policy.record(moment)
            #expect(requester.requestCount == 1, "\(moment)")
        }
    }

    @Test("At most once per app version, across moments and relaunches")
    func oncePerVersion() {
        let (policy, requester, storage, clock) = make()
        clock.date.addTimeInterval(4 * 86_400)
        for moment in Self.allMoments { policy.record(moment) }
        #expect(requester.requestCount == 1)
        #expect(storage.string(forKey: ReviewPromptPolicy.lastPromptedVersionKey) == "1.0")

        let (relaunched, second, _, _) = make(storage: storage, clock: clock)
        relaunched.record(.exportShared)
        #expect(second.requestCount == 0)
    }

    @Test("A new app version may prompt again")
    func newVersionPromptsAgain() {
        let (policy, _, storage, clock) = make()
        clock.date.addTimeInterval(4 * 86_400)
        policy.record(.csvImported)
        let (next, requester, _, _) = make(version: "1.1", storage: storage, clock: clock)
        next.record(.csvImported)
        #expect(requester.requestCount == 1)
    }

    @Test("First launch is stamped once and survives relaunch")
    func firstLaunchStampedOnce() {
        let (_, _, storage, clock) = make()
        let stamp = storage.string(forKey: ReviewPromptPolicy.firstLaunchKey)
        clock.date.addTimeInterval(10 * 86_400)
        _ = make(storage: storage, clock: clock)
        #expect(storage.string(forKey: ReviewPromptPolicy.firstLaunchKey) == stamp)
    }

    @Test("Legacy flags migrate so this version does not prompt again")
    func legacyMigration() {
        for key in ReviewPromptPolicy.legacyKeys {
            let storage = FakeKeyValueStore()
            storage.set(true, forKey: key)
            let (policy, requester, _, clock) = make(version: "2.0", storage: storage)
            clock.date.addTimeInterval(10 * 86_400)
            policy.record(.milestoneCardShared)
            #expect(requester.requestCount == 0)
            #expect(storage.string(forKey: ReviewPromptPolicy.lastPromptedVersionKey) == "2.0")
        }
    }

    @Test("No requester (watch) means no prompt and no version recorded")
    func noRequester() {
        let storage = FakeKeyValueStore()
        let clock = Clock()
        let policy = ReviewPromptPolicy(storage: storage, requester: nil, appVersion: "1.0", now: { clock.date })
        clock.date.addTimeInterval(10 * 86_400)
        policy.record(.csvImported)
        #expect(storage.string(forKey: ReviewPromptPolicy.lastPromptedVersionKey) == nil)
    }
}
