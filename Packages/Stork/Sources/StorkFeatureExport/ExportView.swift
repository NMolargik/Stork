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
                exportRow(icon: "doc.richtext.fill", color: .storkPurple, title: String(localized: "PDF Report", bundle: .module), subtitle: String(localized: "Generate a summary report with charts", bundle: .module)) { showPDFOptions = true }
                exportRow(icon: "tablecells.fill", color: .storkBlue, title: String(localized: "CSV Export", bundle: .module), subtitle: String(localized: "Export data for spreadsheets or backup", bundle: .module)) { showCSVOptions = true }
            } header: {
                Text("Export Data", bundle: .module)
            } footer: {
                Text("Export your delivery records for analysis, backup, or professional portfolios.", bundle: .module)
            }

            Section {
                NavigationLink {
                    ShareCardView(model: model)
                } label: {
                    HStack {
                        Image(systemName: "photo.on.rectangle.angled").font(.title2).foregroundStyle(.storkPink).frame(width: 40).accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Share Cards", bundle: .module).font(.headline)
                            Text("Share statistics and milestones as images", bundle: .module).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
            } header: {
                Text("Share", bundle: .module)
            } footer: {
                Text("Create shareable images of your statistics cards and milestone achievements.", bundle: .module)
            }

            Section(String(localized: "Your Data", bundle: .module)) {
                LabeledContent(String(localized: "Total Deliveries", bundle: .module)) { Text("\(model.deliveries.count)", bundle: .module).foregroundStyle(.secondary) }
                LabeledContent(String(localized: "Total Babies", bundle: .module)) { Text("\(model.totalBabies)", bundle: .module).foregroundStyle(.secondary) }
            }
        }
        .navigationTitle(Text("Export & Share", bundle: .module))
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
