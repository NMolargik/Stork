//
//  ExportManager.swift
//  StorkFeatureExport
//
//  Orchestrates CSV/PDF export and card rendering, writing results to temp files.
//

#if os(iOS)
import Foundation
import SwiftUI
import Observation
import os
import StorkCore

@MainActor
@Observable
public final class ExportManager {
    public var isExporting = false
    public var exportProgress = 0.0
    public var lastError: ExportError?

    private let csvExporter = CSVExporter()
    private let pdfGenerator = PDFReportGenerator()
    private let cardRenderer = CardImageRenderer()

    public init() {}

    // MARK: - CSV

    public func exportCSV(deliveries: [Delivery], dateRange: ExportDateRange, customDateInterval: DateInterval?, rowFormat: CSVRowFormat, useMetricUnits: Bool) throws -> URL {
        isExporting = true
        lastError = nil
        defer { isExporting = false }

        let filtered = filterDeliveries(deliveries, dateRange: dateRange, customInterval: customDateInterval)
        guard !filtered.isEmpty else {
            let error = ExportError.noDataToExport
            lastError = error
            throw error
        }
        do {
            let data = try csvExporter.export(configuration: .init(deliveries: filtered, rowFormat: rowFormat, useMetricUnits: useMetricUnits))
            return try createTempFile(data: data, filename: "stork-deliveries", extension: "csv")
        } catch {
            let exportError = ExportError.csvExportFailed(error.localizedDescription)
            lastError = exportError
            throw exportError
        }
    }

    // MARK: - PDF

    public func generatePDFReport(deliveries: [Delivery], dateRange: ExportDateRange, customDateInterval: DateInterval?, useMetricUnits: Bool, useDayMonthYearDates: Bool) async throws -> URL {
        isExporting = true
        lastError = nil
        exportProgress = 0.0
        defer { isExporting = false; exportProgress = 0.0 }

        let filtered = filterDeliveries(deliveries, dateRange: dateRange, customInterval: customDateInterval)
        guard !filtered.isEmpty else {
            let error = ExportError.noDataToExport
            lastError = error
            throw error
        }
        do {
            exportProgress = 0.1
            let data = try await pdfGenerator.generate(configuration: .init(deliveries: filtered, dateRange: dateRange, customDateInterval: customDateInterval, useMetricUnits: useMetricUnits, useDayMonthYearDates: useDayMonthYearDates)) { progress in
                Task { @MainActor in self.exportProgress = 0.1 + (progress * 0.8) }
            }
            exportProgress = 0.9
            let df = DateFormatter()
            df.dateFormat = "yyyy-MM"
            let url = try createTempFile(data: data, filename: "stork-report-\(df.string(from: Date()))", extension: "pdf")
            exportProgress = 1.0
            return url
        } catch {
            let exportError = ExportError.pdfGenerationFailed(error.localizedDescription)
            lastError = exportError
            throw exportError
        }
    }

    // MARK: - Cards

    public func renderStatCard(type: CardImageRenderer.CardType, deliveries: [Delivery], useMetricUnits: Bool, includeWatermark: Bool = true) -> UIImage? {
        cardRenderer.renderCard(type: type, deliveries: deliveries, useMetricUnits: useMetricUnits, includeWatermark: includeWatermark)
    }

    public func renderMilestoneCard(count: Int, milestoneType: CardImageRenderer.MilestoneType) -> UIImage? {
        cardRenderer.renderMilestoneCard(count: count, milestoneType: milestoneType)
    }

    // MARK: - Helpers

    private func filterDeliveries(_ deliveries: [Delivery], dateRange: ExportDateRange, customInterval: DateInterval?) -> [Delivery] {
        let interval = dateRange == .custom ? customInterval : dateRange.dateInterval()
        guard let interval else { return deliveries }
        return deliveries.filter { interval.contains($0.date) }
    }

    private func createTempFile(data: Data, filename: String, extension ext: String) throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(filename)-\(Int(Date().timeIntervalSince1970)).\(ext)")
        do {
            try data.write(to: url)
            return url
        } catch {
            throw ExportError.fileCreationFailed(error.localizedDescription)
        }
    }
}
#endif
