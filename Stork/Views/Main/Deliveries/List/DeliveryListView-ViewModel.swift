//
//  DeliveryListView-ViewModel.swift
//  Stork
//
//  Created by Nick Molargik on 11/3/25.
//

import SwiftUI

extension DeliveryListView {
    @Observable
    class ViewModel {
        // Source list used by the UI (shows filtered if present, otherwise all)
        func source(from manager: DeliveryManager) -> [Delivery] {
            manager.visibleDeliveries.isEmpty ? manager.deliveries : manager.visibleDeliveries
        }

        // Unique month starts (first of month) in descending order
        func monthStarts(from deliveries: [Delivery]) -> [Date] {
            let cal = Calendar.current
            let starts = deliveries.compactMap { d in
                cal.date(from: cal.dateComponents([.year, .month], from: d.date))
            }
            return Array(Set(starts)).sorted(by: >)
        }

        // Deliveries that fall within the same month as `monthStart`
        func deliveries(in monthStart: Date, from deliveries: [Delivery]) -> [Delivery] {
            let cal = Calendar.current
            return deliveries.filter { d in
                cal.isDate(d.date, equalTo: monthStart, toGranularity: .month)
            }
        }
    }
}
