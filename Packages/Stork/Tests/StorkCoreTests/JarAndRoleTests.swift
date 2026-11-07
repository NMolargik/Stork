//
//  JarAndRoleTests.swift
//  StorkCoreTests
//

import Testing
import Foundation
import StorkCore

@Suite("Jar categories & birth roles")
struct JarAndRoleTests {
    private let cal = Calendar.current
    private func date(_ y: Int, _ m: Int, _ d: Int) -> Date {
        cal.date(from: DateComponents(year: y, month: m, day: d, hour: 12))!
    }

    private func delivery(_ when: Date, method: DeliveryMethod = .vaginal, role: BirthRole? = nil, babies: [Baby]) -> Delivery {
        let d = Delivery(date: when, babies: babies, babyCount: babies.count, deliveryMethod: method, epiduralUsed: false, role: role)
        return d
    }

    @Test("Category priority: remembrance, then nurse catch, then sex")
    func categoryPriority() {
        #expect(JarMarble.category(sex: .loss, nurseCatch: true) == .remembrance)
        #expect(JarMarble.category(sex: .male, nurseCatch: true) == .nurseCatch)
        #expect(JarMarble.category(sex: .male, nurseCatch: false) == .boy)
        #expect(JarMarble.category(sex: .female, nurseCatch: false) == .girl)
    }

    @Test("Twins share a link ID; singletons do not; other months excluded")
    func marblesLinkAndFilter() {
        let twins = delivery(date(2026, 5, 3), method: .cSection, babies: [Baby(sex: .male), Baby(sex: .female)])
        let single = delivery(date(2026, 5, 9), babies: [Baby(nurseCatch: true, sex: .female)])
        let april = delivery(date(2026, 4, 9), babies: [Baby(sex: .male)])
        let marbles = DeliveryStatistics.jarMarbles(deliveries: [twins, single, april], asOf: date(2026, 5, 15))
        #expect(marbles.count == 3)
        #expect(marbles.filter { $0.linkID == twins.id }.count == 2)
        #expect(marbles.filter { $0.linkID != nil }.count == 2)
        #expect(marbles.filter(\.isCSection).count == 2)
        let summary = JarSummary(marbles: marbles)
        #expect(summary.boy == 1 && summary.girl == 1 && summary.nurseCatch == 1)
        #expect(summary.multiples == 2 && summary.cSection == 2)
    }

    @Test("Remembrance is never part of the delivered count")
    func remembranceNotCounted() {
        let d = delivery(date(2026, 5, 3), babies: [Baby(sex: .male), Baby(sex: .loss)])
        let summary = JarSummary(marbles: DeliveryStatistics.jarMarbles(deliveries: [d], asOf: date(2026, 5, 3)))
        #expect(summary.remembrance == 1)
        #expect(summary.delivered == 1)
        #expect(summary.total == 2)
    }

    @Test("New deliveries have no role; role round-trips")
    func roleDefault() {
        let d = delivery(date(2026, 5, 3), babies: [])
        #expect(d.role == nil)
        d.role = .doula
        #expect(d.role == .doula)
    }

    @Test("Role counting setting: default counts all, excluded persists, unrecorded always counts")
    func roleCounting() {
        var counting = BirthRoleCounting(storedValue: "")
        for role in BirthRole.allCases { #expect(counting.counts(role)) }
        counting.set(.student, counted: false)
        counting.set(.doula, counted: false)
        let restored = BirthRoleCounting(storedValue: counting.storedValue)
        #expect(restored == counting)
        #expect(!restored.counts(.student) && restored.counts(.primaryNurse) && restored.counts(nil))
        #expect(BirthRoleCounting(storedValue: "bogus,student").excluded == [.student])
    }

    @Test("Headline totals honor role counting; breakdown groups by role")
    func totalsAndBreakdown() {
        let a = delivery(date(2026, 5, 1), role: .primaryNurse, babies: [Baby(), Baby()])
        let b = delivery(date(2026, 5, 2), role: .student, babies: [Baby()])
        let c = delivery(date(2026, 5, 3), babies: [Baby()])
        let all = [a, b, c]
        #expect(DeliveryStatistics.totals(deliveries: all, counting: .init()).deliveries == 3)
        let only = DeliveryStatistics.totals(deliveries: all, counting: .init(excluded: [.student]))
        #expect(only.deliveries == 2 && only.babies == 3)
        let breakdown = DeliveryStatistics.roleBreakdown(deliveries: all)
        #expect(breakdown.map(\.role) == [.primaryNurse, .student])
        #expect(breakdown.first?.babies == 2)
    }
}
