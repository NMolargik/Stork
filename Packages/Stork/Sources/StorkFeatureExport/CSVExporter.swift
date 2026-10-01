//
//  CSVExporter.swift
//  StorkFeatureExport
//
//  Renders deliveries to CSV (per-delivery or per-baby). Pure Foundation — host-testable.
//

import Foundation
import StorkCore

@MainActor
public final class CSVExporter {

    public struct Configuration {
        public let deliveries: [Delivery]
        public let rowFormat: CSVRowFormat
        public let useMetricUnits: Bool

        public init(deliveries: [Delivery], rowFormat: CSVRowFormat, useMetricUnits: Bool) {
            self.deliveries = deliveries
            self.rowFormat = rowFormat
            self.useMetricUnits = useMetricUnits
        }
    }

    private let dateFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    public init() {}

    public func export(configuration: Configuration) throws -> Data {
        var lines: [String] = [headers(for: configuration.rowFormat)]
        for delivery in configuration.deliveries {
            lines.append(contentsOf: dataRows(for: delivery, format: configuration.rowFormat, useMetric: configuration.useMetricUnits))
        }
        guard let data = lines.joined(separator: "\n").data(using: .utf8) else {
            throw ExportError.csvExportFailed("Failed to encode CSV as UTF-8")
        }
        return data
    }

    private func headers(for format: CSVRowFormat) -> String {
        switch format {
        case .perDelivery:
            ["delivery_id", "date", "delivery_method", "epidural_used", "baby_count"].joined(separator: ",")
        case .perBaby:
            ["delivery_id", "delivery_date", "delivery_method", "epidural_used", "baby_id", "baby_birthday",
             "sex", "weight", "weight_unit", "height", "height_unit", "nurse_catch", "nicu_stay"].joined(separator: ",")
        }
    }

    private func dataRows(for delivery: Delivery, format: CSVRowFormat, useMetric: Bool) -> [String] {
        switch format {
        case .perDelivery:
            return [deliveryRow(delivery)]
        case .perBaby:
            let babies = delivery.babies ?? []
            if babies.isEmpty { return [deliveryWithNoBabyRow(delivery)] }
            return babies.map { babyRow(delivery: delivery, baby: $0, useMetric: useMetric) }
        }
    }

    private func deliveryRow(_ delivery: Delivery) -> String {
        [
            delivery.id.uuidString,
            dateFormatter.string(from: delivery.date),
            delivery.deliveryMethod.rawValue,
            delivery.epiduralUsed ? "true" : "false",
            String(delivery.babyCount),
        ].map(escapeCSV).joined(separator: ",")
    }

    private func deliveryWithNoBabyRow(_ delivery: Delivery) -> String {
        ([
            delivery.id.uuidString,
            dateFormatter.string(from: delivery.date),
            delivery.deliveryMethod.rawValue,
            delivery.epiduralUsed ? "true" : "false",
        ] + Array(repeating: "", count: 9)).map(escapeCSV).joined(separator: ",")
    }

    private func babyRow(delivery: Delivery, baby: Baby, useMetric: Bool) -> String {
        let weight = useMetric ? baby.weight * UnitConversion.ouncesToGrams : baby.weight
        let weightUnit = useMetric ? "g" : "oz"
        let height = useMetric ? baby.height * UnitConversion.inchesToCentimeters : baby.height
        let heightUnit = useMetric ? "cm" : "in"
        return [
            delivery.id.uuidString,
            dateFormatter.string(from: delivery.date),
            delivery.deliveryMethod.rawValue,
            delivery.epiduralUsed ? "true" : "false",
            baby.id.uuidString,
            dateFormatter.string(from: baby.birthday),
            baby.sex.rawValue,
            String(format: "%.1f", weight),
            weightUnit,
            String(format: "%.1f", height),
            heightUnit,
            baby.nurseCatch ? "true" : "false",
            baby.nicuStay ? "true" : "false",
        ].map(escapeCSV).joined(separator: ",")
    }

    private func escapeCSV(_ value: String) -> String {
        if value.contains(",") || value.contains("\"") || value.contains("\n") || value.contains("\r") {
            return "\"\(value.replacingOccurrences(of: "\"", with: "\"\""))\""
        }
        return value
    }
}
