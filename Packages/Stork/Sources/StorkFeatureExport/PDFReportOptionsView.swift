//
//  PDFReportOptionsView.swift
//  StorkFeatureExport
//

#if os(iOS)
import SwiftUI
import StorkCore
import StorkDesignSystem

struct PDFReportOptionsView: View {
    @Environment(\.dismiss) private var dismiss
    let model: ExportModel

    @AppStorage(AppStorageKeys.useMetricUnits) private var useMetricUnits = false
    @AppStorage(AppStorageKeys.useDayMonthYearDates) private var useDayMonthYearDates = false

    @State private var dateRange: ExportDateRange = .thisYear
    @State private var customStartDate = Calendar.current.date(byAdding: .year, value: -1, to: Date()) ?? Date()
    @State private var customEndDate = Date()
    @State private var exportURL: URL?
    @State private var showError = false
    @State private var errorMessage = ""

    private var filteredDeliveries: [Delivery] {
        guard dateRange != .allTime else { return model.deliveries }
        let interval = dateRange == .custom ? DateInterval(start: customStartDate, end: customEndDate) : dateRange.dateInterval()
        guard let interval else { return model.deliveries }
        return model.deliveries.filter { interval.contains($0.date) }
    }

    private var totalBabies: Int {
        filteredDeliveries.reduce(0) { $0 + ($1.babies?.count ?? $1.babyCount) }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(String(localized: "Report Period", bundle: .module)) {
                    Picker(String(localized: "Date Range", bundle: .module), selection: $dateRange) {
                        ForEach(ExportDateRange.allCases) { Text($0.displayName).tag($0) }
                    }
                    if dateRange == .custom {
                        DatePicker(String(localized: "Start Date", bundle: .module), selection: $customStartDate, displayedComponents: .date)
                        DatePicker(String(localized: "End Date", bundle: .module), selection: $customEndDate, displayedComponents: .date)
                    }
                }

                Section {
                    LabeledContent(String(localized: "Deliveries", bundle: .module)) { Text("\(filteredDeliveries.count)", bundle: .module).foregroundStyle(.secondary) }
                    LabeledContent(String(localized: "Babies", bundle: .module)) { Text("\(totalBabies)", bundle: .module).foregroundStyle(.secondary) }
                } header: {
                    Text("Preview", bundle: .module)
                } footer: {
                    Text("The report will include delivery method breakdown, sex distribution, and summary statistics.", bundle: .module)
                }

                Section {
                    if let url = exportURL {
                        ShareLink(item: url) { Label(String(localized: "Share PDF Report", bundle: .module), systemImage: "square.and.arrow.up") }
                            .tint(.storkPurple)
                    } else {
                        Button {
                            Task { await generatePDF() }
                        } label: {
                            HStack {
                                if model.manager.isExporting {
                                    ProgressView().controlSize(.small)
                                    Text("Generating...", bundle: .module)
                                } else {
                                    Text("Generate PDF Report", bundle: .module)
                                }
                            }
                        }
                        .disabled(model.manager.isExporting || filteredDeliveries.isEmpty)
                    }

                    if model.manager.isExporting && model.manager.exportProgress > 0 {
                        ProgressView(value: model.manager.exportProgress) { Text("Progress", bundle: .module) }
                    }
                }
            }
            .navigationTitle(Text("PDF Report", bundle: .module))
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
        }
    }

    private func generatePDF() async {
        do {
            let customInterval = dateRange == .custom ? DateInterval(start: customStartDate, end: customEndDate) : nil
            exportURL = try await model.manager.generatePDFReport(deliveries: model.deliveries, dateRange: dateRange, customDateInterval: customInterval, useMetricUnits: useMetricUnits, useDayMonthYearDates: useDayMonthYearDates)
            Haptics.mediumImpact()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}
#endif
