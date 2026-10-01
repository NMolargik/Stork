//
//  DeliveryListModel.swift
//  StorkFeatureDeliveries
//
//  Drives the delivery list: loads deliveries and tags through use-cases, applies the
//  filter pipeline (search field + filter sheet feed the same `DeliveryFilter`), and
//  deletes. Replaces the old `DeliveryManager` list responsibilities.
//

import Foundation
import Observation
import StorkCore

@MainActor
@Observable
public final class DeliveryListModel {

    private let loadDeliveriesUseCase: any LoadDeliveries
    private let deleteDeliveryUseCase: any DeleteDelivery
    private let loadTagsUseCase: any LoadTags

    public private(set) var deliveries: [Delivery] = []
    public private(set) var availableTags: [DeliveryTag] = []
    public private(set) var lastError: PersistenceError?
    public var filter = DeliveryFilter()

    public init(
        loadDeliveries: any LoadDeliveries,
        deleteDelivery: any DeleteDelivery,
        loadTags: any LoadTags
    ) {
        self.loadDeliveriesUseCase = loadDeliveries
        self.deleteDeliveryUseCase = deleteDelivery
        self.loadTagsUseCase = loadTags
    }

    // MARK: - Loading

    /// Reloads deliveries and tags. On failure the previous data is kept (stale beats
    /// blank) and the error is surfaced through `lastError`.
    public func load() {
        do {
            deliveries = try loadDeliveriesUseCase()
            availableTags = try loadTagsUseCase()
            lastError = nil
        } catch {
            lastError = error
        }
    }

    public func refresh() async { load() }

    // MARK: - Filtering

    public var visibleDeliveries: [Delivery] {
        filter.isEmpty ? deliveries : deliveries.filter { filter.matches($0) }
    }

    public func applyFilter(_ filter: DeliveryFilter) {
        self.filter = filter
    }

    public func setSearchText(_ text: String) {
        filter.searchText = text
    }

    /// Whether any criteria beyond the search field are active.
    public var hasActiveFilters: Bool {
        var withoutSearch = filter
        withoutSearch.searchText = ""
        return !withoutSearch.isEmpty
    }

    public func clearFilters(keepingSearch searchText: String) {
        filter = DeliveryFilter()
        filter.searchText = searchText
    }

    // MARK: - Grouping (newest months first)

    public func monthStarts(from deliveries: [Delivery]) -> [Date] {
        let cal = Calendar.current
        let starts = deliveries.compactMap { cal.date(from: cal.dateComponents([.year, .month], from: $0.date)) }
        return Array(Set(starts)).sorted(by: >)
    }

    public func deliveries(in monthStart: Date, from deliveries: [Delivery]) -> [Delivery] {
        let cal = Calendar.current
        return deliveries.filter { cal.isDate($0.date, equalTo: monthStart, toGranularity: .month) }
    }

    // MARK: - Writing

    public func delete(_ delivery: Delivery) {
        do {
            try deleteDeliveryUseCase(delivery)
            lastError = nil
        } catch {
            lastError = error
        }
        load()
    }
}
