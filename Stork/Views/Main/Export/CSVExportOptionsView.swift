//
//  CSVExportOptionsView.swift
//  Stork
//
//  Created by Nick Molargik on 1/17/26.
//

import SwiftUI
import SwiftData

struct CSVExportOptionsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(DeliveryManager.self) private var deliveryManager
    @Environment(ExportManager.self) private var exportManager

    @AppStorage(AppStorageKeys.useMetricUnits) private var useMetricUnits: Bool = false

    @State private var dateRange: ExportDateRange = .allTime
    @State private var customStartDate: Date = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
    @State private var customEndDate: Date = Date()
    @State private var rowFormat: CSVRowFormat = .perBaby
    @State private var exportURL: URL?
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""

    private var filteredDeliveries: [Delivery] {
        let deliveries = deliveryManager.deliveries
        guard dateRange != .allTime else { return deliveries }

        let interval: DateInterval?
        if dateRange == .custom {
            interval = DateInterval(start: customStartDate, end: customEndDate)
        } else {
            interval = dateRange.dateInterval()
        }

        guard let interval = interval else { return deliveries }
        return deliveries.filter { interval.contains($0.date) }
    }

    private var rowCount: Int {
        switch rowFormat {
        case .perDelivery:
            return filteredDeliveries.count
        case .perBaby:
            return filteredDeliveries.reduce(0) { sum, delivery in
                let babyCount = delivery.babies?.count ?? 0
                return sum + max(babyCount, 1) // At least 1 row per delivery
            }
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Date Range", selection: $dateRange) {
                        ForEach(ExportDateRange.allCases) { range in
                            Text(range.displayName).tag(range)
                        }
                    }

                    if dateRange == .custom {
                        DatePicker("Start Date", selection: $customStartDate, displayedComponents: .date)
                        DatePicker("End Date", selection: $customEndDate, displayedComponents: .date)
                    }
                } header: {
                    Text("Date Range")
                }

                Section {
                    Picker("Row Format", selection: $rowFormat) {
                        ForEach(CSVRowFormat.allCases) { format in
                            VStack(alignment: .leading) {
                                Text(format.displayName)
                                Text(format.description)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
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

                Section {
                    LabeledContent("Deliveries") {
                        Text("\(filteredDeliveries.count)")
                            .foregroundStyle(.secondary)
                    }
                    LabeledContent("Rows to Export") {
                        Text("\(rowCount)")
                            .foregroundStyle(.secondary)
                    }
                    LabeledContent("Units") {
                        Text(useMetricUnits ? "Metric" : "Imperial")
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("Preview")
                }

                Section {
                    if let url = exportURL {
                        ShareLink(item: url) {
                            Label("Share CSV File", systemImage: "square.and.arrow.up")
                        }
                        .tint(.storkBlue)
                    } else {
                        Button {
                            exportCSV()
                        } label: {
                            HStack {
                                if exportManager.isExporting {
                                    ProgressView()
                                        .controlSize(.small)
                                }
                                Text(exportManager.isExporting ? "Exporting..." : "Generate CSV")
                            }
                        }
                        .disabled(exportManager.isExporting || filteredDeliveries.isEmpty)
                    }
                }
            }
            .navigationTitle("Export CSV")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Export Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .onChange(of: dateRange) { _, _ in
                exportURL = nil
            }
            .onChange(of: rowFormat) { _, _ in
                exportURL = nil
            }
        }
    }

    private func exportCSV() {
        do {
            let customInterval = dateRange == .custom
                ? DateInterval(start: customStartDate, end: customEndDate)
                : nil

            let url = try exportManager.exportCSV(
                deliveries: deliveryManager.deliveries,
                dateRange: dateRange,
                customDateInterval: customInterval,
                rowFormat: rowFormat,
                useMetricUnits: useMetricUnits
            )
            exportURL = url
            Haptics.mediumImpact()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}

#Preview {
    CSVExportOptionsView()
        .environment(DeliveryManager(context: PreviewContainer.shared.mainContext))
        .environment(ExportManager())
}

// Preview helper
private enum PreviewContainer {
    static let shared: ModelContainer = {
        let schema = Schema([Delivery.self, User.self, Baby.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try! ModelContainer(for: schema, configurations: [config])
    }()
}
