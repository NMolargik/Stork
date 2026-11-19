//
//  ExportPreviews.swift
//  StorkFeatureExport
//
//  The live previews beside the export options on wide screens (iPad regular width, unfolded
//  iPhone Duo): the PDF report as it will be generated, and the CSV's first rows.
//

#if os(iOS)
import SwiftUI
import PDFKit
import StorkCore

/// Shows PDF data page by page, fitted to the available width. Pure display: no editing.
struct PDFPreviewView: UIViewRepresentable {
    let data: Data

    func makeUIView(context: Context) -> PDFView {
        let view = PDFView()
        view.autoScales = true
        view.displayMode = .singlePageContinuous
        view.displayDirection = .vertical
        view.backgroundColor = .clear
        view.pageShadowsEnabled = true
        return view
    }

    func updateUIView(_ view: PDFView, context: Context) {
        view.document = PDFDocument(data: data)
    }
}

/// The right-hand pane of the PDF options: the report the Generate button will produce.
struct PDFReportPreviewPane: View {
    let deliveries: [Delivery]
    let dateRange: ExportDateRange
    let customInterval: DateInterval?
    let useMetricUnits: Bool
    let useDayMonthYearDates: Bool

    @State private var data: Data?

    /// Everything the rendered page depends on; the preview redraws when it changes.
    private var renderKey: [AnyHashable] {
        [deliveries.map(\.id), dateRange, customInterval?.start, customInterval?.end, useMetricUnits, useDayMonthYearDates]
    }

    var body: some View {
        Group {
            if deliveries.isEmpty {
                ContentUnavailableView {
                    Label(String(localized: "Nothing to Preview", bundle: .module), systemImage: "doc.richtext")
                } description: {
                    Text("There are no deliveries in this period.", bundle: .module)
                }
            } else if let data {
                PDFPreviewView(data: data)
            } else {
                ProgressView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(uiColor: .systemGroupedBackground))
        .accessibilityLabel(Text("PDF report preview", bundle: .module))
        .task(id: renderKey) {
            guard !deliveries.isEmpty else { data = nil; return }
            let config = PDFReportGenerator.Configuration(deliveries: deliveries, dateRange: dateRange, customDateInterval: customInterval, useMetricUnits: useMetricUnits, useDayMonthYearDates: useDayMonthYearDates)
            data = try? await PDFReportGenerator().generate(configuration: config)
        }
    }
}

/// The right-hand pane of the CSV options: the header and first rows of the file.
struct CSVPreviewPane: View {
    let deliveries: [Delivery]
    let rowFormat: CSVRowFormat
    let useMetricUnits: Bool
    let totalRows: Int

    private static let previewRows = 8

    /// The header row and the first rows of the file as cells, without the hidden columns.
    private var table: [[String]] {
        // Only the first few deliveries are rendered: the file's own rows, not a re-implementation.
        let sample = Array(deliveries.prefix(Self.previewRows))
        let config = CSVExporter.Configuration(deliveries: sample, rowFormat: rowFormat, useMetricUnits: useMetricUnits)
        guard let data = try? CSVExporter().export(configuration: config), let text = String(data: data, encoding: .utf8) else { return [] }
        return CSVPreviewTable.make(csv: text, maxRows: Self.previewRows)
    }

    /// A readable cell: ISO dates become short local dates and times, everything else is as exported.
    private static func display(_ cell: String, column: String) -> String {
        if column.hasSuffix("method"), let method = DeliveryMethod(rawValue: cell) { return method.displayName }
        if cell == "true" || cell == "false", column.hasSuffix("used") || column.hasSuffix("catch") || column.hasSuffix("stay") {
            return cell == "true" ? String(localized: "Yes", bundle: .module) : String(localized: "No", bundle: .module)
        }
        if column == "sex", let sex = Sex(rawValue: cell) { return sex.displayName }
        if let date = isoFormatter.date(from: cell) {
            return date.formatted(date: .abbreviated, time: .shortened)
        }
        return cell
    }

    private static let isoFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    private static func title(_ header: String) -> String {
        header.replacingOccurrences(of: "_", with: " ").capitalized
    }

    var body: some View {
        Group {
            if deliveries.isEmpty {
                ContentUnavailableView {
                    Label(String(localized: "Nothing to Preview", bundle: .module), systemImage: "tablecells")
                } description: {
                    Text("There are no deliveries in this period.", bundle: .module)
                }
            } else {
                let table = table
                ScrollView([.horizontal, .vertical]) {
                    VStack(alignment: .leading, spacing: 12) {
                        Grid(alignment: .leading, horizontalSpacing: 20, verticalSpacing: 8) {
                            ForEach(Array(table.enumerated()), id: \.offset) { index, row in
                                GridRow {
                                    ForEach(Array(row.enumerated()), id: \.offset) { column, cell in
                                        Text(verbatim: index == 0 ? Self.title(cell) : Self.display(cell, column: table[0][column]))
                                            .font(index == 0 ? .caption.weight(.semibold) : .caption)
                                            .foregroundStyle(index == 0 ? .primary : .secondary)
                                            .lineLimit(1)
                                            .fixedSize()
                                    }
                                }
                                if index == 0 { Divider().gridCellUnsizedAxes(.horizontal) }
                            }
                        }
                        let remaining = totalRows - max(table.count - 1, 0)
                        if remaining > 0 {
                            Text("^[\(remaining) more row](inflect: true)", bundle: .module)
                                .font(.caption).foregroundStyle(.tertiary)
                        }
                    }
                    .padding(16)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color(uiColor: .systemGroupedBackground))
        .accessibilityLabel(Text("CSV preview", bundle: .module))
    }
}
#endif
