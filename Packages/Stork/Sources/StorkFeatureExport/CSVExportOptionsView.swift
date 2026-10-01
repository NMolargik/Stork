//
//  CSVExportOptionsView.swift
//  StorkFeatureExport
//

#if os(iOS)
import SwiftUI
import StorkCore
import StorkDesignSystem

struct CSVExportOptionsView: View {
    @Environment(\.dismiss) private var dismiss
    let model: ExportModel

    @AppStorage(AppStorageKeys.useMetricUnits) private var useMetricUnits = false

    @State private var dateRange: ExportDateRange = .allTime
    @State private var customStartDate = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
    @State private var customEndDate = Date()
    @State private var rowFormat: CSVRowFormat = .perBaby
    @State private var exportURL: URL?
    @State private var showError = false
    @State private var errorMessage = ""

    private var filteredDeliveries: [Delivery] {
        guard dateRange != .allTime else { return model.deliveries }
        let interval = dateRange == .custom ? DateInterval(start: customStartDate, end: customEndDate) : dateRange.dateInterval()
        guard let interval else { return model.deliveries }
        return model.deliveries.filter { interval.contains($0.date) }
    }

    private var rowCount: Int {
        switch rowFormat {
        case .perDelivery: filteredDeliveries.count
        case .perBaby: filteredDeliveries.reduce(0) { $0 + max($1.babies?.count ?? 0, 1) }
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(String(localized: "Date Range", bundle: .module)) {
                    Picker(String(localized: "Date Range", bundle: .module), selection: $dateRange) {
                        ForEach(ExportDateRange.allCases) { Text($0.displayName).tag($0) }
                    }
                    if dateRange == .custom {
                        DatePicker(String(localized: "Start Date", bundle: .module), selection: $customStartDate, displayedComponents: .date)
                        DatePicker(String(localized: "End Date", bundle: .module), selection: $customEndDate, displayedComponents: .date)
                    }
                }

                Section {
                    Picker(String(localized: "Row Format", bundle: .module), selection: $rowFormat) {
                        ForEach(CSVRowFormat.allCases) { format in
                            VStack(alignment: .leading) {
                                Text(format.displayName)
                                Text(format.description).font(.caption).foregroundStyle(.secondary)
                            }
                            .tag(format)
                        }
                    }
                    .pickerStyle(.inline)
                } header: {
                    Text("Format", bundle: .module)
                } footer: {
                    Text("Per-baby format includes detailed measurements for each baby.", bundle: .module)
                }

                Section(String(localized: "Preview", bundle: .module)) {
                    LabeledContent(String(localized: "Deliveries", bundle: .module)) { Text("\(filteredDeliveries.count)", bundle: .module).foregroundStyle(.secondary) }
                    LabeledContent(String(localized: "Rows to Export", bundle: .module)) { Text("\(rowCount)", bundle: .module).foregroundStyle(.secondary) }
                    LabeledContent(String(localized: "Units", bundle: .module)) { Text(useMetricUnits ? "Metric" : "Imperial").foregroundStyle(.secondary) }
                }

                Section {
                    if let url = exportURL {
                        ShareLink(item: url) { Label(String(localized: "Share CSV File", bundle: .module), systemImage: "square.and.arrow.up") }
                            .tint(.storkBlue)
                    } else {
                        Button {
                            exportCSV()
                        } label: {
                            HStack {
                                if model.manager.isExporting { ProgressView().controlSize(.small) }
                                Text(model.manager.isExporting ? "Exporting..." : "Generate CSV")
                            }
                        }
                        .disabled(model.manager.isExporting || filteredDeliveries.isEmpty)
                    }
                }
            }
            .navigationTitle(Text("Export CSV", bundle: .module))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button(String(localized: "Cancel", bundle: .module)) { dismiss() } }
            }
            .alert(Text("Export Error", bundle: .module), isPresented: $showError) {
                Button(String(localized: "OK", bundle: .module), role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
            .onChange(of: dateRange) { _, _ in exportURL = nil }
            .onChange(of: rowFormat) { _, _ in exportURL = nil }
        }
    }

    private func exportCSV() {
        do {
            let customInterval = dateRange == .custom ? DateInterval(start: customStartDate, end: customEndDate) : nil
            exportURL = try model.manager.exportCSV(deliveries: model.deliveries, dateRange: dateRange, customDateInterval: customInterval, rowFormat: rowFormat, useMetricUnits: useMetricUnits)
            Haptics.mediumImpact()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}
#endif
