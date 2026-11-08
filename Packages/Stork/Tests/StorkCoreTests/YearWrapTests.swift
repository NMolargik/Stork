//
//  YearWrapTests.swift
//  StorkCoreTests
//

import Testing
import Foundation
import StorkCore

@Suite("Year Wrap")
struct YearWrapTests {
    private var cal: Calendar {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "UTC")!
        return c
    }

    private func date(_ y: Int, _ m: Int, _ d: Int, _ h: Int = 12) -> Date {
        cal.date(from: DateComponents(year: y, month: m, day: d, hour: h))!
    }

    private func delivery(_ when: Date, method: DeliveryMethod = .vaginal, role: BirthRole? = nil, _ babies: [Baby]) -> Delivery {
        let d = Delivery(date: when, babies: babies, babyCount: babies.count, deliveryMethod: method, epiduralUsed: false, role: role)
        for b in babies { b.delivery = d }
        return d
    }

    private func build(_ deliveries: [Delivery], year: Int = 2026, counting: BirthRoleCounting = .init()) -> YearWrapStats? {
        YearWrap.build(deliveries: deliveries, year: year, counting: counting, calendar: cal)
    }

    @Test("No celebrated delivery in the year gives no Wrap")
    func emptyYear() {
        #expect(build([]) == nil)
        #expect(build([delivery(date(2025, 3, 1), [Baby(sex: .male)])]) == nil)
        // A year with only a loss is not a celebratory Wrap.
        #expect(build([delivery(date(2026, 3, 1), [Baby(sex: .loss)])]) == nil)
    }

    @Test("Totals, sexes, nurse catches, and multiples")
    func headline() throws {
        let ds = [
            delivery(date(2026, 1, 5), [Baby(sex: .male)]),
            delivery(date(2026, 2, 5), [Baby(nurseCatch: true, sex: .female)]),
            delivery(date(2026, 2, 9), method: .cSection, [Baby(sex: .male), Baby(sex: .female)]),
            delivery(date(2026, 3, 9), method: .vBac, [Baby(sex: .male), Baby(sex: .male), Baby(sex: .female)]),
        ]
        let s = try #require(build(ds))
        #expect(s.deliveries == 4 && s.babies == 7)
        #expect(s.boys == 4 && s.girls == 3 && s.nurseCatches == 1)
        #expect(s.twinSets == 1 && s.higherMultipleSets == 1 && s.multipleSets == 2)
        #expect(s.vaginal == 2 && s.cSection == 1 && s.vBac == 1)
        #expect(s.babiesByMonth.count == 12)
        #expect(s.babiesByMonth[0] == 1 && s.babiesByMonth[1] == 3 && s.babiesByMonth[2] == 3)
    }

    @Test("Losses never inflate a figure and are reported separately")
    func lossesSeparate() throws {
        let ds = [
            delivery(date(2026, 4, 1), [Baby(sex: .female)]),
            delivery(date(2026, 4, 2), [Baby(sex: .loss)]),                        // loss-only delivery
            delivery(date(2026, 4, 3), [Baby(sex: .male), Baby(sex: .loss)]),      // twin set, one lost
        ]
        let s = try #require(build(ds))
        #expect(s.deliveries == 2)           // the loss-only delivery is not a celebrated delivery
        #expect(s.babies == 2)
        #expect(s.boys == 1 && s.girls == 1)
        #expect(s.twinSets == 0)             // the surviving twin is not celebrated as a "set"
        #expect(s.remembrance == 2)
        // The loss-only day must not feed busiest day, streak, or last birth.
        #expect(s.longestStreak == 1)
        #expect(s.lastBirth == date(2026, 4, 3))
    }

    @Test("Role counting setting excludes roles from every figure")
    func roleCounting() throws {
        let ds = [
            delivery(date(2026, 5, 1), role: .primaryNurse, [Baby(sex: .male)]),
            delivery(date(2026, 5, 2), role: .student, [Baby(sex: .female), Baby(sex: .loss)]),
            delivery(date(2026, 5, 3), [Baby(sex: .male)]),                          // unrecorded always counts
        ]
        let all = try #require(build(ds))
        #expect(all.deliveries == 3 && all.babies == 3 && all.remembrance == 1)
        let counting = BirthRoleCounting(excluded: [.student])
        let filtered = try #require(build(ds, counting: counting))
        #expect(filtered.deliveries == 2 && filtered.babies == 2)
        #expect(filtered.remembrance == 0)   // the excluded delivery's loss is excluded too
        #expect(filtered.roles.map(\.role) == [.primaryNurse])
        #expect(YearWrap.availableYears(deliveries: [ds[1]], counting: counting, calendar: cal).isEmpty)
    }

    @Test("Roles breakdown lists recorded roles, most first")
    func roles() throws {
        let ds = [
            delivery(date(2026, 5, 1), role: .doula, [Baby(sex: .male)]),
            delivery(date(2026, 5, 2), role: .midwife, [Baby(sex: .male), Baby(sex: .female)]),
            delivery(date(2026, 5, 3), role: .midwife, [Baby(sex: .male)]),
            delivery(date(2026, 5, 4), [Baby(sex: .male)]),
        ]
        let s = try #require(build(ds))
        #expect(s.roles.map(\.role) == [.midwife, .doula])
        #expect(s.roles[0].deliveries == 2 && s.roles[0].babies == 3)
    }

    @Test("Busiest month and day break ties toward the earlier one")
    func busiest() throws {
        let ds = [
            delivery(date(2026, 3, 4, 8), [Baby(sex: .male)]),
            delivery(date(2026, 3, 4, 20), [Baby(sex: .female)]),
            delivery(date(2026, 3, 20), [Baby(sex: .male)]),
            delivery(date(2026, 7, 1), [Baby(sex: .male)]),
            delivery(date(2026, 7, 2), [Baby(sex: .male)]),
            delivery(date(2026, 7, 3), [Baby(sex: .male)]),
        ]
        let s = try #require(build(ds))
        #expect(s.busiestMonth?.month == 3)   // 3 vs 3 deliveries: earlier month wins
        #expect(s.busiestMonth?.deliveries == 3)
        #expect(s.busiestDay?.deliveries == 2)
        #expect(s.busiestDay?.date == cal.startOfDay(for: date(2026, 3, 4)))
        #expect(s.longestStreak == 3)
    }

    @Test("First and last birth of the year")
    func firstLast() throws {
        let ds = [
            delivery(date(2026, 8, 8), [Baby(sex: .male)]),
            delivery(date(2026, 1, 2), [Baby(sex: .male)]),
            delivery(date(2026, 12, 30), [Baby(sex: .male)]),
            delivery(date(2025, 12, 31), [Baby(sex: .male)]),
        ]
        let s = try #require(build(ds))
        #expect(s.firstBirth == date(2026, 1, 2))
        #expect(s.lastBirth == date(2026, 12, 30))
    }

    @Test("Comparison appears only when the previous year has data")
    func comparison() throws {
        let this = [delivery(date(2026, 2, 1), [Baby(sex: .male)]), delivery(date(2026, 2, 2), [Baby(sex: .male), Baby(sex: .female)])]
        let alone = try #require(build(this))
        #expect(alone.comparison == nil)
        let previous = [delivery(date(2025, 6, 1), [Baby(sex: .male)]), delivery(date(2025, 7, 1), [Baby(sex: .loss)])]
        let withPrevious = try #require(build(this + previous))
        let c = try #require(withPrevious.comparison)
        #expect(c.previousYear == 2025 && c.deliveries == 1 && c.babies == 1)
        #expect(c.deliveryChange == 1 && c.babyChange == 2)
        #expect(c.babyPercentChange == 200)
    }

    @Test("Available years are newest first and skip loss-only years")
    func availableYears() {
        let ds = [
            delivery(date(2024, 1, 1), [Baby(sex: .male)]),
            delivery(date(2026, 1, 1), [Baby(sex: .male)]),
            delivery(date(2025, 1, 1), [Baby(sex: .loss)]),
        ]
        #expect(YearWrap.availableYears(deliveries: ds, calendar: cal) == [2026, 2024])
    }

    @Test("Legacy deliveries without baby rows fall back to babyCount")
    func legacy() throws {
        let d = Delivery(date: date(2026, 9, 1), babyCount: 2, deliveryMethod: .vaginal, epiduralUsed: false)
        let s = try #require(build([d]))
        #expect(s.babies == 2 && s.twinSets == 1 && s.boys == 0)
    }

    @Test("Seasonal prompt covers December 1 through January 31 only")
    func season() {
        #expect(YearWrapSeason.promptYear(now: date(2026, 11, 30), calendar: cal) == nil)
        #expect(YearWrapSeason.promptYear(now: date(2026, 12, 1, 0), calendar: cal) == 2026)
        #expect(YearWrapSeason.promptYear(now: date(2026, 12, 31), calendar: cal) == 2026)
        #expect(YearWrapSeason.promptYear(now: date(2027, 1, 1), calendar: cal) == 2026)
        #expect(YearWrapSeason.promptYear(now: date(2027, 1, 31, 23), calendar: cal) == 2026)
        #expect(YearWrapSeason.promptYear(now: date(2027, 2, 1), calendar: cal) == nil)
        #expect(YearWrapSeason.promptYear(now: date(2026, 6, 15), calendar: cal) == nil)
    }
}
