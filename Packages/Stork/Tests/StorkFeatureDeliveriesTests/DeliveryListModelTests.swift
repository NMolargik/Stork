//
//  DeliveryListModelTests.swift
//  StorkFeatureDeliveriesTests
//
//  Behavior tests for the delivery list view model over fake use-cases: loading,
//  the filter pipeline, month grouping, deletion, and error surfacing.
//

import Testing
import Foundation
import StorkCore
@testable import StorkFeatureDeliveries

@Suite("DeliveryListModel Tests")
@MainActor
struct DeliveryListModelTests {

    @Test("load populates deliveries and tags from the use-cases")
    func loadPopulates() {
        let data = FakeDeliveryData()
        data.deliveries = [Make.delivery(), Make.delivery()]
        data.tags = [DeliveryTag(name: "Night Shift")]
        let model = Make.listModel(data: data)

        model.load()

        #expect(model.deliveries.count == 2)
        #expect(model.availableTags.count == 1)
        #expect(model.lastError == nil)
    }

    @Test("load failure keeps previous data and surfaces the error")
    func loadFailureKeepsStaleData() {
        let data = FakeDeliveryData()
        data.deliveries = [Make.delivery()]
        let model = Make.listModel(data: data)
        model.load()
        #expect(model.deliveries.count == 1)

        data.errorToThrow = .fetchFailed("disk full")
        data.deliveries = []
        model.load()

        // Stale beats blank: the previously loaded delivery is still shown.
        #expect(model.deliveries.count == 1)
        #expect(model.lastError != nil)
    }

    @Test("visibleDeliveries applies the active filter")
    func filterPipeline() {
        let data = FakeDeliveryData()
        data.deliveries = [
            Make.delivery(method: .vaginal),
            Make.delivery(method: .cSection),
        ]
        let model = Make.listModel(data: data)
        model.load()

        var filter = DeliveryFilter()
        filter.deliveryMethod = [.cSection]
        model.applyFilter(filter)

        #expect(model.deliveries.count == 2)
        #expect(model.visibleDeliveries.count == 1)
        #expect(model.visibleDeliveries.first?.deliveryMethod == .cSection)
    }

    @Test("hasActiveFilters ignores search text; clearFilters keeps it")
    func searchTextIsNotAFilter() {
        let data = FakeDeliveryData()
        let model = Make.listModel(data: data)

        model.setSearchText("twins")
        #expect(!model.hasActiveFilters)

        var filter = model.filter
        filter.epiduralUsedOnly = true
        model.applyFilter(filter)
        #expect(model.hasActiveFilters)

        model.clearFilters(keepingSearch: "twins")
        #expect(!model.hasActiveFilters)
        #expect(model.filter.searchText == "twins")
    }

    @Test("month grouping buckets deliveries and orders newest month first")
    func monthGrouping() {
        let cal = Calendar.current
        let january = cal.date(from: DateComponents(year: 2026, month: 1, day: 10))!
        let march = cal.date(from: DateComponents(year: 2026, month: 3, day: 5))!
        let marchAgain = cal.date(from: DateComponents(year: 2026, month: 3, day: 20))!

        let data = FakeDeliveryData()
        data.deliveries = [Make.delivery(date: january), Make.delivery(date: march), Make.delivery(date: marchAgain)]
        let model = Make.listModel(data: data)
        model.load()

        let months = model.monthStarts(from: model.deliveries)
        #expect(months.count == 2)
        #expect(months.first.map { cal.component(.month, from: $0) } == 3)
        #expect(model.deliveries(in: months[0], from: model.deliveries).count == 2)
        #expect(model.deliveries(in: months[1], from: model.deliveries).count == 1)
    }

    @Test("delete routes through the use-case and reloads")
    func deleteRoutesAndReloads() {
        let data = FakeDeliveryData()
        let doomed = Make.delivery()
        data.deliveries = [doomed, Make.delivery()]
        let model = Make.listModel(data: data)
        model.load()

        model.delete(doomed)

        #expect(data.deletedDeliveries.map(\.id) == [doomed.id])
        #expect(model.deliveries.count == 1)
        #expect(model.lastError == nil)
    }
}
