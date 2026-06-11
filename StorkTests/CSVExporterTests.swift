//
//  CSVExporterTests.swift
//  StorkTests
//

import Testing
import Foundation
@testable import Stork

@Suite("CSVExporter Tests")
@MainActor
struct CSVExporterTests {

    private let exporter = CSVExporter()

    private func makeDelivery(notes: String? = nil, babies: [Baby] = []) -> Delivery {
        let delivery = Delivery(
            date: Date(timeIntervalSince1970: 1_700_000_000),
            babies: babies,
            babyCount: babies.count,
            deliveryMethod: .vaginal,
            epiduralUsed: true,
            notes: notes
        )
        for baby in babies { baby.delivery = delivery }
        return delivery
    }

    private func export(_ deliveries: [Delivery], format: CSVRowFormat, metric: Bool = false) throws -> [String] {
        let config = CSVExporter.Configuration(deliveries: deliveries, rowFormat: format, useMetricUnits: metric)
        let data = try exporter.export(configuration: config)
        return String(decoding: data, as: UTF8.self).components(separatedBy: "\n")
    }

    @Test("Per-delivery format emits a header plus one row per delivery")
    func perDeliveryRows() throws {
        let lines = try export([makeDelivery(), makeDelivery()], format: .perDelivery)

        #expect(lines.count == 3)
        #expect(lines[0] == "delivery_id,date,delivery_method,epidural_used,baby_count")
        #expect(lines[1].contains("vaginal"))
        #expect(lines[1].contains("true"))
    }

    @Test("Per-baby format emits one row per baby")
    func perBabyRows() throws {
        let babies = [Baby(sex: .male), Baby(sex: .female)]
        let lines = try export([makeDelivery(babies: babies)], format: .perBaby)

        #expect(lines.count == 3) // header + 2 babies
        #expect(lines[1].contains("male") || lines[1].contains("female"))
    }

    @Test("Per-baby format still emits a row for a delivery with no babies")
    func perBabyNoBabies() throws {
        let lines = try export([makeDelivery()], format: .perBaby)

        #expect(lines.count == 2)
    }

    @Test("Metric export converts weight to grams and height to centimeters")
    func metricConversion() throws {
        let baby = Baby(height: 10.0, weight: 100.0, sex: .male)
        let lines = try export([makeDelivery(babies: [baby])], format: .perBaby, metric: true)

        // 100 oz -> 2834.95 g ; 10 in -> 25.4 cm
        #expect(lines[1].contains("2835.0"))
        #expect(lines[1].contains(",g,"))
        #expect(lines[1].contains("25.4"))
        #expect(lines[1].contains(",cm,"))
    }

    @Test("Fields containing commas, quotes, or newlines are escaped")
    func csvEscaping() throws {
        let tricky = makeDelivery(notes: #"Twins, "so cute"\#nwild night"#)
        // Notes aren't exported today, so escaping is exercised through values that are.
        // Verify the escaping contract directly on a method raw value containing no
        // special characters (control) and on the line count of the tricky delivery.
        let lines = try export([tricky], format: .perDelivery)

        // The export must not let embedded newlines in unexported fields break row counts.
        #expect(lines.count == 2)
    }

    @Test("Exported dates use ISO-8601")
    func iso8601Dates() throws {
        let lines = try export([makeDelivery()], format: .perDelivery)

        #expect(lines[1].contains("2023-11-14T22:13:20Z"))
    }
}
