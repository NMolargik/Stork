//
//  ExportView.swift
//  Stork
//
//  Created by Nick Molargik on 1/17/26.
//

import SwiftUI
import SwiftData

struct ExportView: View {
    @Environment(DeliveryManager.self) private var deliveryManager

    @State private var showCSVOptions = false
    @State private var showPDFOptions = false

    var body: some View {
        List {
            Section {
                // PDF Report
                Button {
                    showPDFOptions = true
                } label: {
                    HStack {
                        Image(systemName: "doc.richtext.fill")
                            .font(.title2)
                            .foregroundStyle(.storkPurple)
                            .frame(width: 40)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("PDF Report")
                                .font(.headline)
                            Text("Generate a summary report with charts")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .foregroundStyle(.tertiary)
                    }
                }
                .buttonStyle(.plain)

                // CSV Export
                Button {
                    showCSVOptions = true
                } label: {
                    HStack {
                        Image(systemName: "tablecells.fill")
                            .font(.title2)
                            .foregroundStyle(.storkBlue)
                            .frame(width: 40)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("CSV Export")
                                .font(.headline)
                            Text("Export data for spreadsheets or backup")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .foregroundStyle(.tertiary)
                    }
                }
                .buttonStyle(.plain)
            } header: {
                Text("Export Data")
            } footer: {
                Text("Export your delivery records for analysis, backup, or professional portfolios.")
            }

            Section {
                NavigationLink {
                    ShareCardView()
                } label: {
                    HStack {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.title2)
                            .foregroundStyle(.storkPink)
                            .frame(width: 40)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Share Cards")
                                .font(.headline)
                            Text("Share statistics and milestones as images")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            } header: {
                Text("Share")
            } footer: {
                Text("Create shareable images of your statistics cards and milestone achievements.")
            }

            // Stats preview
            Section {
                LabeledContent("Total Deliveries") {
                    Text("\(deliveryManager.deliveries.count)")
                        .foregroundStyle(.secondary)
                }

                LabeledContent("Total Babies") {
                    let count = deliveryManager.deliveries.reduce(0) { $0 + ($1.babies?.count ?? $1.babyCount) }
                    Text("\(count)")
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text("Your Data")
            }
        }
        .navigationTitle("Export & Share")
        .sheet(isPresented: $showCSVOptions) {
            CSVExportOptionsView()
        }
        .sheet(isPresented: $showPDFOptions) {
            PDFReportOptionsView()
        }
    }
}

#Preview {
    NavigationStack {
        ExportView()
            .environment(DeliveryManager(context: PreviewContainer.shared.mainContext))
            .environment(UserManager(context: PreviewContainer.shared.mainContext))
            .environment(ExportManager())
    }
}

private enum PreviewContainer {
    static let shared: ModelContainer = {
        let schema = Schema([Delivery.self, User.self, Baby.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try! ModelContainer(for: schema, configurations: [config])
    }()
}
