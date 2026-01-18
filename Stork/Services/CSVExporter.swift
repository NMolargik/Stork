//
//  CSVExporter.swift
//  Stork
//
//  Created by Nick Molargik on 1/17/26.
//

import Foundation

@MainActor
final class CSVExporter {

    struct Configuration {
        let deliveries: [Delivery]
        let rowFormat: CSVRowFormat
        let useMetricUnits: Bool
    }

    private let dateFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    func export(configuration: Configuration) throws -> Data {
        var lines: [String] = []

        // Header row
        lines.append(headers(for: configuration.rowFormat))

        // Data rows
        for delivery in configuration.deliveries {
            let rows = dataRows(for: delivery, format: configuration.rowFormat, useMetric: configuration.useMetricUnits)
            lines.append(contentsOf: rows)
        }

        let csvString = lines.joined(separator: "\n")
        guard let data = csvString.data(using: .utf8) else {
            throw ExportError.csvExportFailed("Failed to encode CSV as UTF-8")
        }

        return data
    }

    private func headers(for format: CSVRowFormat) -> String {
        switch format {
        case .perDelivery:
            return [
                "delivery_id",
                "date",
                "delivery_method",
                "epidural_used",
                "baby_count"
            ].joined(separator: ",")

        case .perBaby:
            return [
                "delivery_id",
                "delivery_date",
                "delivery_method",
                "epidural_used",
                "baby_id",
                "baby_birthday",
                "sex",
                "weight",
                "weight_unit",
                "height",
                "height_unit",
                "nurse_catch",
                "nicu_stay"
            ].joined(separator: ",")
        }
    }

    private func dataRows(for delivery: Delivery, format: CSVRowFormat, useMetric: Bool) -> [String] {
        switch format {
        case .perDelivery:
            return [deliveryRow(delivery)]

        case .perBaby:
            let babies = delivery.babies ?? []
            if babies.isEmpty {
                // Still output a row for the delivery even with no babies
                return [deliveryWithNoBabyRow(delivery)]
            }
            return babies.map { baby in
                babyRow(delivery: delivery, baby: baby, useMetric: useMetric)
            }
        }
    }

    private func deliveryRow(_ delivery: Delivery) -> String {
        let fields: [String] = [
            delivery.id.uuidString,
            dateFormatter.string(from: delivery.date),
            delivery.deliveryMethod.rawValue,
            delivery.epiduralUsed ? "true" : "false",
            String(delivery.babyCount)
        ]
        return fields.map { escapeCSV($0) }.joined(separator: ",")
    }

    private func deliveryWithNoBabyRow(_ delivery: Delivery) -> String {
        let fields: [String] = [
            delivery.id.uuidString,
            dateFormatter.string(from: delivery.date),
            delivery.deliveryMethod.rawValue,
            delivery.epiduralUsed ? "true" : "false",
            "", // baby_id
            "", // baby_birthday
            "", // sex
            "", // weight
            "", // weight_unit
            "", // height
            "", // height_unit
            "", // nurse_catch
            ""  // nicu_stay
        ]
        return fields.map { escapeCSV($0) }.joined(separator: ",")
    }

    private func babyRow(delivery: Delivery, baby: Baby, useMetric: Bool) -> String {
        let weight: Double
        let weightUnit: String
        let height: Double
        let heightUnit: String

        if useMetric {
            weight = baby.weight * UnitConversion.ouncesToGrams
            weightUnit = "g"
            height = baby.height * UnitConversion.inchesToCentimeters
            heightUnit = "cm"
        } else {
            weight = baby.weight
            weightUnit = "oz"
            height = baby.height
            heightUnit = "in"
        }

        let fields: [String] = [
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
            baby.nicuStay ? "true" : "false"
        ]
        return fields.map { escapeCSV($0) }.joined(separator: ",")
    }

    private func escapeCSV(_ value: String) -> String {
        // If value contains comma, quote, or newline, wrap in quotes and escape quotes
        if value.contains(",") || value.contains("\"") || value.contains("\n") || value.contains("\r") {
            let escaped = value.replacingOccurrences(of: "\"", with: "\"\"")
            return "\"\(escaped)\""
        }
        return value
    }
}
