//
//  CSVExporterTests.swift
//  StorkFeatureExportTests
//
//  Host-side tests for the pure CSV exporter.
//

import Testing
import Foundation
import StorkCore
@testable import StorkFeatureExport

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
        #expect(lines.count == 3)
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
        #expect(lines[1].contains("2835.0"))
        #expect(lines[1].contains(",g,"))
        #expect(lines[1].contains("25.4"))
        #expect(lines[1].contains(",cm,"))
    }

    @Test("Exported dates use ISO-8601")
    func iso8601Dates() throws {
        let lines = try export([makeDelivery()], format: .perDelivery)
        #expect(lines[1].contains("2023-11-14T22:13:20Z"))
    }
}
