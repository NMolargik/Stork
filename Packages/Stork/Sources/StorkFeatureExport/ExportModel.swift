//
//  ExportModel.swift
//  StorkFeatureExport
//
//  Supplies deliveries and the shared ExportManager to the export screens.
//

#if os(iOS)
import Foundation
import Observation
import StorkCore

@MainActor
@Observable
public final class ExportModel {
    private let loadDeliveriesUseCase: any LoadDeliveries
    public let manager = ExportManager()
    public private(set) var deliveries: [Delivery] = []

    public init(loadDeliveries: any LoadDeliveries) {
        self.loadDeliveriesUseCase = loadDeliveries
    }

    public func load() {
        deliveries = (try? loadDeliveriesUseCase()) ?? []
    }

    public var totalBabies: Int {
        deliveries.reduce(0) { $0 + ($1.babies?.count ?? $1.babyCount) }
    }
}
#endif
