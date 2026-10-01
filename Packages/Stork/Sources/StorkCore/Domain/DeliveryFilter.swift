//
//  DeliveryFilter.swift
//  StorkCore
//
//  The value type describing how the delivery list is filtered. The search field and
//  the filter sheet both feed this through one pipeline. Matching logic lives in
//  `DeliveryFilter+Matching`.
//

import Foundation

public struct DeliveryFilter: Equatable {
    public var dateRange: ClosedRange<Date>?
    public var babyCount: Int?
    public var deliveryMethod: Set<DeliveryMethod>
    public var epiduralUsedOnly: Bool
    /// Searches delivery-method text, note contents, and tag names.
    public var searchText: String
    /// Matches a delivery that carries ANY of the selected tag ids.
    public var selectedTagIds: Set<UUID>
    public var hasNotesOnly: Bool

    public init(
        dateRange: ClosedRange<Date>? = nil,
        babyCount: Int? = nil,
        deliveryMethod: Set<DeliveryMethod> = [],
        epiduralUsedOnly: Bool = false,
        searchText: String = "",
        selectedTagIds: Set<UUID> = [],
        hasNotesOnly: Bool = false
    ) {
        self.dateRange = dateRange
        self.babyCount = babyCount
        self.deliveryMethod = deliveryMethod
        self.epiduralUsedOnly = epiduralUsedOnly
        self.searchText = searchText
        self.selectedTagIds = selectedTagIds
        self.hasNotesOnly = hasNotesOnly
    }
}
