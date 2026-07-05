//
//  DomainTests.swift
//  StorkCoreTests
//
//  Tests for the pure domain layer: week math, filtering, milestones, and deep-link
//  parsing.
//

import Testing
import Foundation
import StorkCore

// MARK: - WeekMath

@Suite("WeekMath Tests")
struct WeekMathTests {

    private func date(_ year: Int, _ month: Int, _ day: Int, hour: Int = 12) -> Date {
        Calendar.current.date(from: DateComponents(year: year, month: month, day: day, hour: hour))!
    }

    @Test("Week range starts on Sunday and ends the following Sunday")
    func weekRangeBounds() {
        let range = WeekMath.weekRange(containing: date(2026, 6, 10))
        let cal = WeekMath.sundayFirstCalendar
        #expect(cal.component(.weekday, from: range.start) == 1)
        #expect(cal.dateComponents([.day], from: range.start, to: range.end).day == 7)
        #expect(cal.component(.day, from: range.start) == 7)
    }

    @Test("Week range contains its start but not its end")
    func weekRangeContainment() {
        let range = WeekMath.weekRange(containing: date(2026, 6, 10))
        #expect(range.contains(range.start))
        #expect(!range.contains(range.end))
        #expect(range.contains(date(2026, 6, 13)))
        #expect(!range.contains(date(2026, 6, 14)))
    }

    @Test("A Sunday maps to a week starting that same day")
    func sundayStartsItsOwnWeek() {
        let sunday = date(2026, 6, 7)
        let range = WeekMath.weekRange(containing: sunday)
        #expect(WeekMath.sundayFirstCalendar.isDate(range.start, inSameDayAs: sunday))
    }

    @Test("startOfMonth returns the first of the month at midnight")
    func startOfMonth() {
        let result = WeekMath.startOfMonth(for: date(2026, 6, 10))
        let comps = Calendar.current.dateComponents([.year, .month, .day, .hour], from: result)
        #expect(comps.year == 2026)
        #expect(comps.month == 6)
        #expect(comps.day == 1)
        #expect(comps.hour == 0)
    }

    @Test("monthStarts walks backward from anchor to oldest")
    func monthStarts() {
        let anchor = WeekMath.startOfMonth(for: date(2026, 6, 1))
        let oldest = WeekMath.startOfMonth(for: date(2026, 1, 1))
        let months = WeekMath.monthStarts(from: oldest, anchor: anchor)
        #expect(months.count == 6)
        #expect(months.first == anchor)
        #expect(months.last == oldest)
    }

    @Test("Formatted week string spans Sunday through Saturday")
    func formattedWeekString() {
        let range = WeekMath.weekRange(containing: date(2026, 6, 10))
        let formatted = WeekMath.formattedWeekString(range)
        #expect(formatted.contains("Jun 7"))
        #expect(formatted.contains("Jun 13"))
    }

    @Test("Month header title formats as MMM 'yy")
    func monthHeaderTitle() {
        let title = WeekMath.monthHeaderTitle(for: WeekMath.startOfMonth(for: date(2026, 6, 1)))
        #expect(title.contains("'26"))
        #expect(title.uppercased() == title)
    }
}

// MARK: - DeliveryFilter matching

@MainActor
@Suite("DeliveryFilter Matching Tests")
struct DeliveryFilterMatchingTests {

    private func makeDelivery(
        date: Date = .now,
        babyCount: Int = 1,
        method: DeliveryMethod = .vaginal,
        epidural: Bool = false,
        notes: String? = nil,
        tags: [DeliveryTag] = []
    ) -> Delivery {
        Delivery(date: date, babyCount: babyCount, deliveryMethod: method, epiduralUsed: epidural, notes: notes, tags: tags)
    }

    @Test("Empty filter matches everything and reports isEmpty")
    func emptyFilter() {
        let filter = DeliveryFilter()
        #expect(filter.isEmpty)
        #expect(filter.matches(makeDelivery()))
        #expect(filter.matches(makeDelivery(method: .cSection, epidural: true)))
    }

    @Test("Date range filter excludes deliveries outside the range")
    func dateRangeFilter() {
        var filter = DeliveryFilter()
        let now = Date()
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: now)!
        let monthAgo = Calendar.current.date(byAdding: .day, value: -30, to: now)!
        filter.dateRange = weekAgo...now
        #expect(!filter.isEmpty)
        #expect(filter.matches(makeDelivery(date: now)))
        #expect(!filter.matches(makeDelivery(date: monthAgo)))
    }

    @Test("Baby count filter requires exact match")
    func babyCountFilter() {
        var filter = DeliveryFilter()
        filter.babyCount = 2
        #expect(filter.matches(makeDelivery(babyCount: 2)))
        #expect(!filter.matches(makeDelivery(babyCount: 1)))
    }

    @Test("Method filter matches any selected method")
    func methodFilter() {
        var filter = DeliveryFilter()
        filter.deliveryMethod = [.cSection, .vBac]
        #expect(filter.matches(makeDelivery(method: .cSection)))
        #expect(filter.matches(makeDelivery(method: .vBac)))
        #expect(!filter.matches(makeDelivery(method: .vaginal)))
    }

    @Test("Epidural-only filter excludes non-epidural deliveries")
    func epiduralFilter() {
        var filter = DeliveryFilter()
        filter.epiduralUsedOnly = true
        #expect(filter.matches(makeDelivery(epidural: true)))
        #expect(!filter.matches(makeDelivery(epidural: false)))
    }

    @Test("Search text matches method name or notes, case-insensitively")
    func searchTextFilter() {
        var filter = DeliveryFilter()
        filter.searchText = "MEMORABLE"
        #expect(filter.matches(makeDelivery(notes: "Such a memorable delivery")))
        #expect(!filter.matches(makeDelivery(notes: "Routine")))
        #expect(!filter.matches(makeDelivery(notes: nil)))
        filter.searchText = "vag"
        #expect(filter.matches(makeDelivery(method: .vaginal)))
    }

    @Test("Search text matches tag names, case-insensitively")
    func searchTextMatchesTags() {
        var filter = DeliveryFilter()
        filter.searchText = "night"
        let tagged = makeDelivery(tags: [DeliveryTag(name: "Night Shift")])
        #expect(filter.matches(tagged))
        #expect(!filter.matches(makeDelivery(tags: [DeliveryTag(name: "First Solo")])))
        #expect(!filter.matches(makeDelivery(tags: [])))
    }

    @Test("Tag filter matches when delivery has any selected tag")
    func tagFilter() {
        let tagA = DeliveryTag(name: "Night Shift")
        let tagB = DeliveryTag(name: "Memorable")
        var filter = DeliveryFilter()
        filter.selectedTagIds = [tagA.id]
        #expect(filter.matches(makeDelivery(tags: [tagA, tagB])))
        #expect(!filter.matches(makeDelivery(tags: [tagB])))
        #expect(!filter.matches(makeDelivery(tags: [])))
    }

    @Test("Has-notes filter excludes empty and missing notes")
    func hasNotesFilter() {
        var filter = DeliveryFilter()
        filter.hasNotesOnly = true
        #expect(filter.matches(makeDelivery(notes: "A note")))
        #expect(!filter.matches(makeDelivery(notes: "")))
        #expect(!filter.matches(makeDelivery(notes: nil)))
    }

    @Test("Combined criteria must all pass")
    func combinedFilter() {
        var filter = DeliveryFilter()
        filter.babyCount = 1
        filter.epiduralUsedOnly = true
        #expect(filter.matches(makeDelivery(babyCount: 1, epidural: true)))
        #expect(!filter.matches(makeDelivery(babyCount: 1, epidural: false)))
        #expect(!filter.matches(makeDelivery(babyCount: 2, epidural: true)))
    }
}

// MARK: - MilestoneTracker

@Suite("MilestoneTracker Tests")
struct MilestoneTrackerTests {

    @Test("No milestone below the first threshold")
    func belowFirstThreshold() {
        let tracker = MilestoneTracker(storage: FakeKeyValueStore())
        #expect(tracker.checkForNewMilestone(totalBabies: 99, totalDeliveries: 49) == nil)
    }

    @Test("Crossing a baby milestone returns it once")
    func babyMilestoneOnce() {
        let tracker = MilestoneTracker(storage: FakeKeyValueStore())
        let first = tracker.checkForNewMilestone(totalBabies: 100, totalDeliveries: 0)
        #expect(first == MilestoneCelebration(count: 100, type: .babies))
        let second = tracker.checkForNewMilestone(totalBabies: 100, totalDeliveries: 0)
        #expect(second == nil)
    }

    @Test("Baby milestones outrank delivery milestones")
    func babyPriority() {
        let tracker = MilestoneTracker(storage: FakeKeyValueStore())
        let result = tracker.checkForNewMilestone(totalBabies: 100, totalDeliveries: 50)
        #expect(result?.type == .babies)
        let next = tracker.checkForNewMilestone(totalBabies: 100, totalDeliveries: 50)
        #expect(next == MilestoneCelebration(count: 50, type: .deliveries))
    }

    @Test("Highest crossed milestone wins when several cross at once")
    func highestWins() {
        let tracker = MilestoneTracker(storage: FakeKeyValueStore())
        let result = tracker.checkForNewMilestone(totalBabies: 600, totalDeliveries: 0)
        #expect(result == MilestoneCelebration(count: 500, type: .babies))
    }

    @Test("Celebrated milestones persist through storage")
    func persistence() {
        let store = FakeKeyValueStore()
        let result = MilestoneTracker(storage: store)
            .checkForNewMilestone(totalBabies: 100, totalDeliveries: 0)
        #expect(result != nil)
        let rebuilt = MilestoneTracker(storage: store)
        #expect(rebuilt.checkForNewMilestone(totalBabies: 100, totalDeliveries: 0) == nil)
    }
}

// MARK: - DeepLink parsing

@Suite("DeepLink Parsing Tests")
struct DeepLinkParsingTests {

    @Test("Recognized hosts parse to their deep links", arguments: [
        ("stork://new-delivery", DeepLink.newDelivery),
        ("stork://dashboard", DeepLink.dashboard),
        ("stork://deliveries", DeepLink.deliveries),
        ("stork://deliveries/week", DeepLink.weeklyDeliveries),
        ("stork://calendar", DeepLink.calendar),
        ("stork://settings", DeepLink.settings),
    ])
    func parsesKnownLinks(urlString: String, expected: DeepLink) {
        let url = URL(string: urlString)!
        #expect(DeepLink(url: url) == expected)
    }

    @Test("Wrong scheme and unknown hosts are rejected")
    func rejectsUnknown() {
        #expect(DeepLink(url: URL(string: "https://deliveries")!) == nil)
        #expect(DeepLink(url: URL(string: "stork://unknown")!) == nil)
    }

    @Test("Delivery links parse their UUID and reject malformed ones")
    func deliveryLink() {
        let id = UUID()
        #expect(DeepLink(url: URL(string: "stork://delivery/\(id.uuidString)")!) == .delivery(id))
        #expect(DeepLink(url: URL(string: "stork://delivery/not-a-uuid")!) == nil)
        #expect(DeepLink(url: URL(string: "stork://delivery")!) == nil)
    }
}
