//
//  ExportManager.swift
//  Stork
//
//  Created by Nick Molargik on 1/17/26.
//

import Foundation
import SwiftUI
import Observation

@MainActor
@Observable
class ExportManager {
    // MARK: - State
    var isExporting: Bool = false
    var exportProgress: Double = 0.0
    var lastError: ExportError?

    // MARK: - Services
    private let csvExporter = CSVExporter()
    private let pdfGenerator = PDFReportGenerator()
    private let cardRenderer = CardImageRenderer()

    // MARK: - CSV Export

    func exportCSV(
        deliveries: [Delivery],
        dateRange: ExportDateRange,
        customDateInterval: DateInterval?,
        rowFormat: CSVRowFormat,
        useMetricUnits: Bool
    ) throws -> URL {
        isExporting = true
        lastError = nil
        defer { isExporting = false }

        let filtered = filterDeliveries(deliveries, dateRange: dateRange, customInterval: customDateInterval)

        guard !filtered.isEmpty else {
            let error = ExportError.noDataToExport
            lastError = error
            throw error
        }

        let config = CSVExporter.Configuration(
            deliveries: filtered,
            rowFormat: rowFormat,
            useMetricUnits: useMetricUnits
        )

        do {
            let csvData = try csvExporter.export(configuration: config)
            let url = try createTempFile(data: csvData, filename: "stork-deliveries", extension: "csv")
            return url
        } catch {
            let exportError = ExportError.csvExportFailed(error.localizedDescription)
            lastError = exportError
            throw exportError
        }
    }

    // MARK: - PDF Report

    func generatePDFReport(
        user: User,
        deliveries: [Delivery],
        dateRange: ExportDateRange,
        customDateInterval: DateInterval?,
        useMetricUnits: Bool,
        useDayMonthYearDates: Bool
    ) async throws -> URL {
        isExporting = true
        lastError = nil
        exportProgress = 0.0
        defer {
            isExporting = false
            exportProgress = 0.0
        }

        let filtered = filterDeliveries(deliveries, dateRange: dateRange, customInterval: customDateInterval)

        guard !filtered.isEmpty else {
            let error = ExportError.noDataToExport
            lastError = error
            throw error
        }

        let config = PDFReportGenerator.Configuration(
            user: user,
            deliveries: filtered,
            dateRange: dateRange,
            customDateInterval: customDateInterval,
            useMetricUnits: useMetricUnits,
            useDayMonthYearDates: useDayMonthYearDates
        )

        do {
            exportProgress = 0.1
            let pdfData = try await pdfGenerator.generate(configuration: config) { progress in
                Task { @MainActor in
                    self.exportProgress = 0.1 + (progress * 0.8)
                }
            }
            exportProgress = 0.9

            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM"
            let dateStr = dateFormatter.string(from: Date())
            let url = try createTempFile(data: pdfData, filename: "stork-report-\(dateStr)", extension: "pdf")

            exportProgress = 1.0
            return url
        } catch {
            let exportError = ExportError.pdfGenerationFailed(error.localizedDescription)
            lastError = exportError
            throw exportError
        }
    }

    // MARK: - Card Rendering

    func renderStatCard(
        type: CardImageRenderer.CardType,
        deliveries: [Delivery],
        useMetricUnits: Bool,
        includeWatermark: Bool = true
    ) -> UIImage? {
        cardRenderer.renderCard(
            type: type,
            deliveries: deliveries,
            useMetricUnits: useMetricUnits,
            includeWatermark: includeWatermark
        )
    }

    func renderMilestoneCard(
        count: Int,
        milestoneType: CardImageRenderer.MilestoneType,
        userName: String?
    ) -> UIImage? {
        cardRenderer.renderMilestoneCard(
            count: count,
            milestoneType: milestoneType,
            userName: userName
        )
    }

    // MARK: - Helpers

    private func filterDeliveries(
        _ deliveries: [Delivery],
        dateRange: ExportDateRange,
        customInterval: DateInterval?
    ) -> [Delivery] {
        let interval: DateInterval?

        if dateRange == .custom {
            interval = customInterval
        } else {
            interval = dateRange.dateInterval()
        }

        guard let interval = interval else {
            return deliveries // All time - no filtering
        }

        return deliveries.filter { delivery in
            interval.contains(delivery.date)
        }
    }

    private func createTempFile(data: Data, filename: String, extension ext: String) throws -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let timestamp = Int(Date().timeIntervalSince1970)
        let url = tempDir.appendingPathComponent("\(filename)-\(timestamp).\(ext)")

        do {
            try data.write(to: url)
            return url
        } catch {
            throw ExportError.fileCreationFailed(error.localizedDescription)
        }
    }

    func cleanupTempFiles() {
        let tempDir = FileManager.default.temporaryDirectory
        let fileManager = FileManager.default

        do {
            let files = try fileManager.contentsOfDirectory(at: tempDir, includingPropertiesForKeys: nil)
            for file in files {
                let filename = file.lastPathComponent
                if filename.hasPrefix("stork-") && (filename.hasSuffix(".csv") || filename.hasSuffix(".pdf")) {
                    try? fileManager.removeItem(at: file)
                }
            }
        } catch {
            print("Failed to cleanup temp files: \(error)")
        }
    }
}
