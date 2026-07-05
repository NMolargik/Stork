//
//  CalendarModel.swift
//  StorkFeatureDashboard
//
//  Supplies deliveries to the calendar tab.
//

import Foundation
import Observation
import StorkCore

@MainActor
@Observable
public final class CalendarModel {
    private let loadDeliveriesUseCase: any LoadDeliveries
    public private(set) var deliveries: [Delivery] = []

    public init(loadDeliveries: any LoadDeliveries) {
        self.loadDeliveriesUseCase = loadDeliveries
    }

    public func load() {
        deliveries = (try? loadDeliveriesUseCase()) ?? []
    }

    public func refresh() async { load() }
}
