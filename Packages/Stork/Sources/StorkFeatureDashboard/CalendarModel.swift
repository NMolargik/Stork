//
//  CalendarModel.swift
//  StorkFeatureDashboard
//
//  Supplies deliveries to the calendar tab and gates the Pro heat-map view.
//

import Foundation
import Observation
import StorkCore

@MainActor
@Observable
public final class CalendarModel {
    private let loadDeliveriesUseCase: any LoadDeliveries
    private let entitlement: any EntitlementProviding
    public private(set) var deliveries: [Delivery] = []

    public init(loadDeliveries: any LoadDeliveries, entitlement: any EntitlementProviding) {
        self.loadDeliveriesUseCase = loadDeliveries
        self.entitlement = entitlement
    }

    public var isProUnlocked: Bool { entitlement.isProUnlocked }

    /// The heat map renders only for Pro users who turned it on; everyone else sees dots.
    public func showsHeatMap(preferenceEnabled: Bool) -> Bool {
        isProUnlocked && preferenceEnabled
    }

    public func load() {
        deliveries = ((try? loadDeliveriesUseCase()) ?? []).filter { !$0.isEstimated }
    }

    public func refresh() async { load() }
}
