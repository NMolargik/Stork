//
//  DeliveryFilter.swift
//  Stork
//
//  Created by Nick Molargik on 10/4/25.
//

import Foundation

struct DeliveryFilter: Equatable {
    var dateRange: ClosedRange<Date>? = nil
    var babyCount: Int? = nil
    var deliveryMethod: Set<DeliveryMethod> = []
    var epiduralUsedOnly: Bool = false
    var searchText: String = "" // searches hospital name, delivery method raw string value, or note contents
    
    static var previewValue: DeliveryFilter {
        var f = DeliveryFilter()
        // Example defaults for preview
        f.babyCount = 5
        f.searchText = ""
        // Leave dateRange and requiredTriggers empty by default
        return f
    }

    static var previewWithRange: DeliveryFilter {
        var f = DeliveryFilter.previewValue
        let now = Date()
        let twoWeeksAgo = Calendar.current.date(byAdding: .day, value: -14, to: now) ?? now
        f.dateRange = twoWeeksAgo...now
        return f
    }
}
