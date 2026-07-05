//
//  ExportView.swift
//  StorkFeatureExport
//
//  Hub for PDF/CSV export and shareable cards.
//

#if os(iOS)
import SwiftUI
import StorkCore
import StorkDesignSystem

public struct ExportView: View {
    @Bindable private var model: ExportModel
    @State private var showCSVOptions = false
    @State private var showPDFOptions = false

    public init(model: ExportModel) {
        self.model = model
    }

    public var body: some View {
        List {
            Section {
                exportRow(icon: "doc.richtext.fill", color: .storkPurple, title: "PDF Report", subtitle: "Generate a summary report with charts") { showPDFOptions = true }
                exportRow(icon: "tablecells.fill", color: .storkBlue, title: "CSV Export", subtitle: "Export data for spreadsheets or backup") { showCSVOptions = true }
            } header: {
                Text("Export Data")
            } footer: {
                Text("Export your delivery records for analysis, backup, or professional portfolios.")
            }

            Section {
                NavigationLink {
                    ShareCardView(model: model)
                } label: {
                    HStack {
                        Image(systemName: "photo.on.rectangle.angled").font(.title2).foregroundStyle(.storkPink).frame(width: 40).accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Share Cards").font(.headline)
                            Text("Share statistics and milestones as images").font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
            } header: {
                Text("Share")
            } footer: {
                Text("Create shareable images of your statistics cards and milestone achievements.")
            }

            Section("Your Data") {
                LabeledContent("Total Deliveries") { Text("\(model.deliveries.count)").foregroundStyle(.secondary) }
                LabeledContent("Total Babies") { Text("\(model.totalBabies)").foregroundStyle(.secondary) }
            }
        }
        .navigationTitle("Export & Share")
        .onAppear { model.load() }
        .sheet(isPresented: $showCSVOptions) { CSVExportOptionsView(model: model) }
        .sheet(isPresented: $showPDFOptions) { PDFReportOptionsView(model: model) }
    }

    @ContentBuilder
    private func exportRow(icon: String, color: Color, title: String, subtitle: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon).font(.title2).foregroundStyle(color).frame(width: 40).accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.headline)
                    Text(subtitle).font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundStyle(.tertiary).accessibilityHidden(true)
            }
        }
        .buttonStyle(.plain)
    }
}
#endif
