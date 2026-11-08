//
//  CSVImportModel.swift
//  StorkFeatureSettings
//
//  Backs the CSV import screen: holds the chosen file's text, builds the preview with
//  per-row status through `DeliveryCSVImport` (Core), and imports the ready rows in one
//  transaction. Identifier columns never make it past the preview.
//

import Foundation
import Observation
import StorkCore

@MainActor
@Observable
public final class CSVImportModel {

    private let loadDeliveries: any LoadDeliveries
    private let importDeliveries: any ImportDeliveries
    private let now: () -> Date
    private let calendar: Calendar

    public private(set) var fileName: String?
    public private(set) var preview: CSVImportPreview?
    public var includeDuplicates = false
    public private(set) var lastError: PersistenceError?
    public private(set) var readError: String?
    public private(set) var importedCount: Int?

    public init(
        loadDeliveries: any LoadDeliveries,
        importDeliveries: any ImportDeliveries,
        now: @escaping () -> Date = { Date() },
        calendar: Calendar = .current
    ) {
        self.loadDeliveries = loadDeliveries
        self.importDeliveries = importDeliveries
        self.now = now
        self.calendar = calendar
    }

    /// Builds the preview from raw CSV text (already read from the chosen file).
    public func load(csv: String, fileName: String?) {
        self.fileName = fileName
        readError = nil
        importedCount = nil
        let existing = (try? loadDeliveries()) ?? []
        preview = DeliveryCSVImport.preview(csv: csv, existing: existing, now: now(), calendar: calendar)
    }

    public func loadFile(at url: URL) {
        let scoped = url.startAccessingSecurityScopedResource()
        defer { if scoped { url.stopAccessingSecurityScopedResource() } }
        do {
            let data = try Data(contentsOf: url)
            guard let text = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .isoLatin1) else {
                readError = String(localized: "That file could not be read as text.", bundle: .module)
                return
            }
            load(csv: text, fileName: url.lastPathComponent)
        } catch {
            readError = String(localized: "That file could not be opened.", bundle: .module)
        }
    }

    public func reset() {
        preview = nil
        fileName = nil
        importedCount = nil
        readError = nil
        includeDuplicates = false
    }

    /// Rows that would be imported with the current duplicate setting.
    public var importableCount: Int {
        guard let preview else { return 0 }
        return preview.readyCount + (includeDuplicates ? preview.duplicateCount : 0)
    }

    @discardableResult
    public func performImport() -> Bool {
        guard let preview, importableCount > 0 else { return false }
        let deliveries = DeliveryCSVImport.makeDeliveries(from: preview, includeDuplicates: includeDuplicates)
        do {
            try importDeliveries(deliveries)
            importedCount = deliveries.count
            lastError = nil
            return true
        } catch {
            lastError = error
            return false
        }
    }

    public static let templateCSV = DeliveryCSVImport.template
}
