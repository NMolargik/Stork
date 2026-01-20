//
//  PDFReportOptionsView.swift
//  Stork
//
//  Created by Nick Molargik on 1/17/26.
//

import SwiftUI
import SwiftData

struct PDFReportOptionsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(DeliveryManager.self) private var deliveryManager
    @Environment(UserManager.self) private var userManager
    @Environment(ExportManager.self) private var exportManager

    @AppStorage(AppStorageKeys.useMetricUnits) private var useMetricUnits: Bool = false
    @AppStorage(AppStorageKeys.useDayMonthYearDates) private var useDayMonthYearDates: Bool = false

    @State private var dateRange: ExportDateRange = .thisYear
    @State private var customStartDate: Date = Calendar.current.date(byAdding: .year, value: -1, to: Date()) ?? Date()
    @State private var customEndDate: Date = Date()
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

    private var totalBabies: Int {
        filteredDeliveries.reduce(0) { $0 + ($1.babies?.count ?? $1.babyCount) }
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
                    Text("Report Period")
                }

                Section {
                    LabeledContent("Deliveries") {
                        Text("\(filteredDeliveries.count)")
                            .foregroundStyle(.secondary)
                    }
                    LabeledContent("Babies") {
                        Text("\(totalBabies)")
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("Preview")
                } footer: {
                    Text("The report will include delivery method breakdown, sex distribution, and summary statistics.")
                }

                Section {
                    if let url = exportURL {
                        ShareLink(item: url) {
                            Label("Share PDF Report", systemImage: "square.and.arrow.up")
                        }
                        .tint(.storkPurple)
                    } else {
                        Button {
                            Task {
                                await generatePDF()
                            }
                        } label: {
                            HStack {
                                if exportManager.isExporting {
                                    ProgressView()
                                        .controlSize(.small)
                                    Text("Generating...")
                                } else {
                                    Text("Generate PDF Report")
                                }
                            }
                        }
                        .disabled(exportManager.isExporting || filteredDeliveries.isEmpty)
                    }

                    if exportManager.isExporting && exportManager.exportProgress > 0 {
                        ProgressView(value: exportManager.exportProgress) {
                            Text("Progress")
                        }
                    }
                }
            }
            .navigationTitle("PDF Report")
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
        }
    }

    private func generatePDF() async {
        do {
            let customInterval = dateRange == .custom
                ? DateInterval(start: customStartDate, end: customEndDate)
                : nil

            let url = try await exportManager.generatePDFReport(
                deliveries: deliveryManager.deliveries,
                dateRange: dateRange,
                customDateInterval: customInterval,
                useMetricUnits: useMetricUnits,
                useDayMonthYearDates: useDayMonthYearDates
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
    PDFReportOptionsView()
        .environment(DeliveryManager(context: PreviewContainer.shared.mainContext))
        .environment(UserManager(context: PreviewContainer.shared.mainContext))
        .environment(ExportManager())
}

private enum PreviewContainer {
    static let shared: ModelContainer = {
        let schema = Schema([Delivery.self, User.self, Baby.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try! ModelContainer(for: schema, configurations: [config])
    }()
}
