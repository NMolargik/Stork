//
//  DeliveryFilter+Matching.swift
//  Stork
//

import Foundation

extension DeliveryFilter {

    /// Whether `delivery` passes every active criterion of this filter.
    func matches(_ delivery: Delivery) -> Bool {
        if let dateRange, !dateRange.contains(delivery.date) {
            return false
        }

        if let babyCount, delivery.babyCount != babyCount {
            return false
        }

        if !deliveryMethod.isEmpty, !deliveryMethod.contains(delivery.deliveryMethod) {
            return false
        }

        if epiduralUsedOnly, !delivery.epiduralUsed {
            return false
        }

        if !searchText.isEmpty {
            let needle = searchText.lowercased()
            let matchesMethod = delivery.deliveryMethod.rawValue.lowercased().contains(needle)
            let matchesNotes = delivery.notes?.lowercased().contains(needle) ?? false
            let matchesTags = (delivery.tags ?? []).contains { $0.name.lowercased().contains(needle) }
            guard matchesMethod || matchesNotes || matchesTags else { return false }
        }

        // Tag filtering: a delivery matches if it has ANY of the selected tags.
        if !selectedTagIds.isEmpty {
            let deliveryTagIds = Set((delivery.tags ?? []).map(\.id))
            guard !deliveryTagIds.isDisjoint(with: selectedTagIds) else { return false }
        }

        if hasNotesOnly {
            guard let notes = delivery.notes, !notes.isEmpty else { return false }
        }

        return true
    }

    /// True when no criteria are active, i.e. every delivery matches.
    var isEmpty: Bool {
        dateRange == nil &&
        babyCount == nil &&
        deliveryMethod.isEmpty &&
        !epiduralUsedOnly &&
        searchText.isEmpty &&
        selectedTagIds.isEmpty &&
        !hasNotesOnly
    }
}
