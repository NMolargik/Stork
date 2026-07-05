//
//  DashboardModel.swift
//  StorkFeatureDashboard
//
//  Loads deliveries for the dashboard and owns the persisted card order. Statistics math
//  stays in `DeliveryStatistics` (pure, unit-tested); this model just supplies the data.
//

import Foundation
import Observation
import StorkCore

@MainActor
@Observable
public final class DashboardModel {

    private let loadDeliveriesUseCase: any LoadDeliveries
    private let store: any KeyValueStoring

    public private(set) var deliveries: [Delivery] = []
    public var cardOrder: [DashboardCard]

    public init(loadDeliveries: any LoadDeliveries, store: any KeyValueStoring = UserDefaults.standard) {
        self.loadDeliveriesUseCase = loadDeliveries
        self.store = store
        self.cardOrder = DashboardCard.loadOrder(from: store)
    }

    public func load() {
        deliveries = (try? loadDeliveriesUseCase()) ?? []
        cardOrder = DashboardCard.loadOrder(from: store)
    }

    public func refresh() async { load() }

    public func saveOrder(_ order: [DashboardCard]) {
        cardOrder = order
        DashboardCard.saveOrder(order, to: store)
    }

    public var monthlyJarCounts: (boy: Int, girl: Int, loss: Int) {
        DeliveryStatistics.monthlyJarCounts(deliveries: deliveries)
    }

    public func jarCounts(forMonthStarting monthStart: Date) -> (boy: Int, girl: Int, loss: Int) {
        DeliveryStatistics.monthlyJarCounts(deliveries: deliveries, asOf: monthStart)
    }
}
