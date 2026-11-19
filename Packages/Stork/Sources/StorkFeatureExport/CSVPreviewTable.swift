//
//  CSVPreviewTable.swift
//  StorkFeatureExport
//
//  The on-screen CSV preview as cells: the exporter's own text, parsed, minus the identifier
//  columns (the exported file keeps them). Pure Foundation, host-testable.
//

import Foundation

nonisolated enum CSVPreviewTable {
    /// Columns left out of the on-screen preview only.
    static let hiddenColumns: Set<String> = ["delivery_id", "baby_id"]

    /// Parses `csv` and keeps the header plus `maxRows` rows, dropping `hiddenColumns`.
    static func make(csv: String, maxRows: Int) -> [[String]] {
        let rows = parse(csv).prefix(maxRows + 1)
        guard let header = rows.first else { return [] }
        let keep = header.indices.filter { !hiddenColumns.contains(header[$0]) }
        return rows.map { row in keep.map { $0 < row.count ? row[$0] : "" } }
    }

    /// Minimal RFC 4180 parser (quoted fields, doubled quotes, embedded commas and newlines).
    static func parse(_ text: String) -> [[String]] {
        var rows: [[String]] = []
        var row: [String] = []
        var field = ""
        var inQuotes = false
        let chars = Array(text)
        var i = 0
        while i < chars.count {
            let ch = chars[i]
            if inQuotes {
                if ch == "\"" {
                    if i + 1 < chars.count, chars[i + 1] == "\"" { field.append("\""); i += 1 } else { inQuotes = false }
                } else { field.append(ch) }
            } else if ch == "\"" {
                inQuotes = true
            } else if ch == "," {
                row.append(field); field = ""
            } else if ch == "\n" || ch == "\r\n" {
                row.append(field); field = ""
                rows.append(row); row = []
            } else if ch != "\r" {
                field.append(ch)
            }
            i += 1
        }
        if !field.isEmpty || !row.isEmpty { row.append(field); rows.append(row) }
        return rows
    }
}
