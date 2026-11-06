//
//  ExportModel.swift
//  StorkFeatureExport
//
//  Supplies deliveries and the shared ExportManager to the export screens, gates the Pro
//  exports, and reports milestone-card shares (the review prompt hangs off the first one).
//

#if os(iOS)
import Foundation
import Observation
import StorkCore

@MainActor
@Observable
public final class ExportModel {
    private let loadDeliveriesUseCase: any LoadDeliveries
    private let entitlement: any EntitlementProviding
    public let manager = ExportManager()
    public private(set) var deliveries: [Delivery] = []

    /// Set by the composition root; fires once per completed milestone-card share.
    @ObservationIgnored public var onMilestoneCardShared: () -> Void = {}

    public init(loadDeliveries: any LoadDeliveries, entitlement: any EntitlementProviding) {
        self.loadDeliveriesUseCase = loadDeliveries
        self.entitlement = entitlement
    }

    /// PDF/CSV export and milestone cards are Stork Pro; statistics share cards stay free.
    public var isProUnlocked: Bool { entitlement.isProUnlocked }

    public func noteMilestoneCardShared() {
        onMilestoneCardShared()
    }

    public func load() {
        deliveries = (try? loadDeliveriesUseCase()) ?? []
    }

    public var totalBabies: Int {
        deliveries.reduce(0) { $0 + ($1.babies?.count ?? $1.babyCount) }
    }
}
#endif
