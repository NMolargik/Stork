//
//  YearWrapModelTests.swift
//  StorkFeatureDashboardTests
//

import Testing
import Foundation
import StorkCore
@testable import StorkFeatureDashboard

private final class WrapFakeStore: KeyValueStoring {
    var storage: [String: Any] = [:]
    func bool(forKey defaultName: String) -> Bool { storage[defaultName] as? Bool ?? false }
    func integer(forKey defaultName: String) -> Int { storage[defaultName] as? Int ?? 0 }
    func stringArray(forKey defaultName: String) -> [String]? { nil }
    func data(forKey defaultName: String) -> Data? { nil }
    func set(_ value: Any?, forKey defaultName: String) { storage[defaultName] = value }
    func set(_ value: Bool, forKey defaultName: String) { storage[defaultName] = value }
    func set(_ value: Int, forKey defaultName: String) { storage[defaultName] = value }
}

private final class WrapFakeEntitlement: EntitlementProviding {
    var isProUnlocked = false   // the Wrap must work for free users
}

private struct WrapLoad: LoadDeliveries {
    var deliveries: [Delivery]
    func callAsFunction() throws(PersistenceError) -> [Delivery] { deliveries }
}

@Suite("Year Wrap model")
@MainActor
struct YearWrapModelTests {
    private let cal = Calendar.current

    private func birth(_ y: Int, _ m: Int, _ d: Int, loss: Bool = false, role: BirthRole? = nil) -> Delivery {
        let when = cal.date(from: DateComponents(year: y, month: m, day: d, hour: 12))!
        let baby = Baby(sex: loss ? .loss : .female)
        let delivery = Delivery(date: when, babies: [baby], babyCount: 1, deliveryMethod: .vaginal, epiduralUsed: false, role: role)
        baby.delivery = delivery
        return delivery
    }

    private func dashboard(_ deliveries: [Delivery], now: Date, store: WrapFakeStore = WrapFakeStore()) -> DashboardModel {
        let model = DashboardModel(loadDeliveries: WrapLoad(deliveries: deliveries), entitlement: WrapFakeEntitlement(), store: store, now: { now })
        model.load()
        return model
    }

    private func day(_ y: Int, _ m: Int, _ d: Int) -> Date { cal.date(from: DateComponents(year: y, month: m, day: d, hour: 9))! }

    @Test("Invitation shows Dec 1 through Jan 31 for the year just ending, only with data")
    func prompt() {
        let data = [birth(2026, 3, 1)]
        let none = BirthRoleCounting()
        #expect(dashboard(data, now: day(2026, 11, 30)).wrapPromptYear(counting: none) == nil)
        #expect(dashboard(data, now: day(2026, 12, 1)).wrapPromptYear(counting: none) == 2026)
        #expect(dashboard(data, now: day(2027, 1, 31)).wrapPromptYear(counting: none) == 2026)
        #expect(dashboard(data, now: day(2027, 2, 1)).wrapPromptYear(counting: none) == nil)
        #expect(dashboard([birth(2025, 3, 1)], now: day(2026, 12, 5)).wrapPromptYear(counting: none) == nil)
    }

    @Test("Dismissing hides the invitation for that year only")
    func dismiss() {
        let store = WrapFakeStore()
        let model = dashboard([birth(2026, 3, 1), birth(2027, 1, 2)], now: day(2026, 12, 5), store: store)
        model.dismissWrapPrompt(year: 2026)
        #expect(model.wrapPromptYear(counting: BirthRoleCounting()) == nil)
        let next = dashboard([birth(2026, 3, 1), birth(2027, 1, 2)], now: day(2027, 12, 5), store: store)
        #expect(next.wrapPromptYear(counting: BirthRoleCounting()) == 2027)
    }

    @Test("Menu years honor the role-counting setting")
    func years() {
        let model = dashboard([birth(2025, 1, 1, role: .student), birth(2026, 1, 1)], now: day(2026, 6, 1))
        #expect(model.wrapYears(counting: BirthRoleCounting()) == [2026, 2025])
        #expect(model.wrapYears(counting: BirthRoleCounting(excluded: [.student])) == [2026])
    }

    @Test("Pages adapt to the data; remembrance stays off the image by default")
    func pagesAndRemembrance() {
        let store = WrapFakeStore()
        let data = [birth(2026, 3, 1), birth(2026, 3, 2, loss: true)]
        let model = YearWrapModel(deliveries: data, year: 2026, counting: BirthRoleCounting(), store: store)
        #expect(model.pages == [.intro, .arrivals, .rhythm, .summary])   // no roles, no previous year
        #expect(model.stats?.remembrance == 1)
        #expect(model.remembranceForImage == nil)
        model.includeRemembranceOnImage = true
        #expect(model.remembranceForImage == 1)
        #expect(store.bool(forKey: AppStorageKeys.wrapShareIncludesRemembrance))

        let rich = YearWrapModel(deliveries: [birth(2026, 3, 1, role: .doula), birth(2025, 3, 1)], year: 2026, counting: BirthRoleCounting(), store: WrapFakeStore())
        #expect(rich.pages == [.intro, .arrivals, .roles, .rhythm, .comparison, .summary])
    }

    @Test("Nothing to remember means nothing on the image even when opted in")
    func noRemembrance() {
        let store = WrapFakeStore()
        store.set(true, forKey: AppStorageKeys.wrapShareIncludesRemembrance)
        let model = YearWrapModel(deliveries: [birth(2026, 3, 1)], year: 2026, counting: BirthRoleCounting(), store: store)
        #expect(model.remembranceForImage == nil)
    }
}
