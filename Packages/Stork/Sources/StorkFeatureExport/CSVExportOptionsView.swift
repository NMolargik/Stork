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
                Section("Date Range") {
                    Picker("Date Range", selection: $dateRange) {
                        ForEach(ExportDateRange.allCases) { Text($0.displayName).tag($0) }
                    }
                    if dateRange == .custom {
                        DatePicker("Start Date", selection: $customStartDate, displayedComponents: .date)
                        DatePicker("End Date", selection: $customEndDate, displayedComponents: .date)
                    }
                }

                Section {
                    Picker("Row Format", selection: $rowFormat) {
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
                    Text("Format")
                } footer: {
                    Text("Per-baby format includes detailed measurements for each baby.")
                }

                Section("Preview") {
                    LabeledContent("Deliveries") { Text("\(filteredDeliveries.count)").foregroundStyle(.secondary) }
                    LabeledContent("Rows to Export") { Text("\(rowCount)").foregroundStyle(.secondary) }
                    LabeledContent("Units") { Text(useMetricUnits ? "Metric" : "Imperial").foregroundStyle(.secondary) }
                }

                Section {
                    if let url = exportURL {
                        ShareLink(item: url) { Label("Share CSV File", systemImage: "square.and.arrow.up") }
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
            .navigationTitle("Export CSV")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
            }
            .alert("Export Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
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
