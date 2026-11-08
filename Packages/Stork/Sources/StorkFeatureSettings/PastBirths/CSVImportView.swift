//
//  CSVImportView.swift
//  StorkFeatureSettings
//
//  Pick a CSV, review a preview with per-row errors and duplicates, then import. Columns
//  that look like patient identifiers are dropped and called out. Includes a downloadable
//  template.
//

#if os(iOS)
import SwiftUI
import UniformTypeIdentifiers
import StorkCore
import StorkDesignSystem

struct CSVTemplateDocument: FileDocument {
    static let readableContentTypes: [UTType] = [.commaSeparatedText]
    init() {}
    init(configuration: ReadConfiguration) throws {}
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: Data(DeliveryCSVImport.template.utf8))
    }
}

struct CSVImportView: View {
    @Bindable var model: CSVImportModel
    @Environment(\.dismiss) private var dismiss
    @Environment(ToastManager.self) private var toast

    @State private var showingPicker = false
    @State private var showingTemplateExporter = false

    var body: some View {
        List {
            if let preview = model.preview {
                previewContent(preview)
            } else {
                startContent
            }
        }
        .navigationTitle(Text("Import from CSV", bundle: .module))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if model.preview != nil {
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "Import", bundle: .module)) { runImport() }
                        .buttonStyle(.borderedProminent).tint(.storkBlue)
                        .disabled(model.importableCount == 0)
                }
            }
        }
        .fileImporter(isPresented: $showingPicker, allowedContentTypes: [.commaSeparatedText, .plainText]) { result in
            if case .success(let url) = result { model.loadFile(at: url) }
        }
        .fileExporter(isPresented: $showingTemplateExporter, document: CSVTemplateDocument(), contentType: .commaSeparatedText, defaultFilename: "stork-import-template") { _ in }
        #if DEBUG
        .task {
            if let path = DebugLaunchOptions.importCSVPath, model.preview == nil, let text = try? String(contentsOfFile: path, encoding: .utf8) {
                model.load(csv: text, fileName: (path as NSString).lastPathComponent)
            }
        }
        #endif
    }

    // MARK: - Before a file is chosen

    @ViewBuilder private var startContent: some View {
        Section {
            Button { showingPicker = true } label: {
                Label(String(localized: "Choose CSV File", bundle: .module), systemImage: "doc.badge.plus")
            }
            Button { showingTemplateExporter = true } label: {
                Label(String(localized: "Download Template", bundle: .module), systemImage: "arrow.down.doc")
            }
            if let message = model.readError {
                Text(message).foregroundStyle(.red).font(.footnote)
            }
        } footer: {
            Text("You will see a preview before anything is added.", bundle: .module)
        }

        Section {
            columnRow("date", note: "Required. 2026-03-14 or 3/14/2026")
            columnRow("sex", note: "boy, girl or loss. Use boy;girl for twins")
            columnRow("babies", note: "1 to 6")
            columnRow("role", note: "primary nurse, midwife, doula and so on")
            columnRow("method", note: "vaginal, cesarean or vbac")
            columnRow("notes", note: "Short personal notes")
        } header: {
            Text("Columns", bundle: .module)
        } footer: {
            Label {
                Text("Stork never imports names or patient identifiers. Columns such as name, MRN or date of birth are dropped automatically, and so are notes that look like them.", bundle: .module)
            } icon: {
                Image(systemName: "hand.raised.fill").foregroundStyle(.storkPurple)
            }
        }
    }

    private func columnRow(_ name: String, note: LocalizedStringKey) -> some View {
        LabeledContent {
            Text(note, bundle: .module).font(.caption).foregroundStyle(.secondary).multilineTextAlignment(.trailing)
        } label: {
            Text(verbatim: name).font(.body.monospaced())
        }
    }

    // MARK: - Preview

    @ViewBuilder private func previewContent(_ preview: CSVImportPreview) -> some View {
        Section {
            if let name = model.fileName {
                LabeledContent(String(localized: "File", bundle: .module), value: name)
            }
            if preview.isEmptyFile {
                Text("This file is empty.", bundle: .module).foregroundStyle(.secondary)
            } else if preview.missingDateColumn {
                Label {
                    Text("No date column found. Add a column named date and try again.", bundle: .module)
                } icon: { Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.red) }
            } else {
                HStack(spacing: 8) {
                    countChip(preview.readyCount, label: "ready", color: .green)
                    countChip(preview.duplicateCount, label: "duplicates", color: .orange)
                    countChip(preview.errorCount, label: "errors", color: .red)
                }
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                if preview.duplicateCount > 0 {
                    Toggle(isOn: $model.includeDuplicates) {
                        Text("Import duplicates anyway", bundle: .module)
                    }
                    .tint(.storkPurple)
                }
            }
            Button(role: .cancel) { model.reset() } label: {
                Label(String(localized: "Choose a Different File", bundle: .module), systemImage: "arrow.counterclockwise")
            }
        } header: {
            Text("Preview", bundle: .module)
        }

        if !preview.droppedColumns.isEmpty {
            Section {
                ForEach(preview.droppedColumns, id: \.self) { name in
                    Label(name, systemImage: "eye.slash").foregroundStyle(.secondary)
                }
            } header: {
                Text("Columns Not Imported", bundle: .module)
            } footer: {
                Text("These columns look like patient identifiers, so Stork ignored them.", bundle: .module)
            }
        }

        // Problems first, then a capped sample of the rest.
        let problems = preview.rows.filter { $0.status != .ready }
        if !problems.isEmpty {
            Section {
                ForEach(problems) { row in rowView(row) }
            } header: {
                Text("Needs Attention", bundle: .module)
            }
        }
        let ready = preview.rows.filter { $0.status == .ready }
        if !ready.isEmpty {
            Section {
                ForEach(ready.prefix(25)) { row in rowView(row) }
            } header: {
                Text("Ready to Import", bundle: .module)
            } footer: {
                if ready.count > 25 {
                    Text("Showing the first 25 of \(ready.count) rows.", bundle: .module)
                }
            }
        }
    }

    private func countChip(_ count: Int, label: LocalizedStringKey, color: Color) -> some View {
        VStack(spacing: 2) {
            Text(verbatim: "\(count)").font(.title3.bold().monospacedDigit()).foregroundStyle(color)
            Text(label, bundle: .module).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }

    private func rowView(_ row: CSVImportRow) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Image(systemName: icon(for: row.status)).foregroundStyle(color(for: row.status)).accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text("Row \(row.id)", bundle: .module).font(.caption).foregroundStyle(.secondary)
                switch row.status {
                case .error(let error):
                    Text(error.message).font(.subheadline)
                case .duplicate:
                    Text(row.draft?.summary() ?? "").font(.subheadline)
                    Text("Already in Stork. Skipped unless you import duplicates.", bundle: .module).font(.caption).foregroundStyle(.orange)
                case .ready:
                    Text(row.draft?.summary() ?? "").font(.subheadline)
                }
                ForEach(Array(row.warnings.enumerated()), id: \.offset) { _, warning in
                    Text(warning.message).font(.caption).foregroundStyle(.secondary)
                }
            }
        }
        .accessibilityElement(children: .combine)
    }

    private func icon(for status: CSVImportRow.Status) -> String {
        switch status {
        case .ready: "checkmark.circle.fill"
        case .duplicate: "doc.on.doc.fill"
        case .error: "exclamationmark.triangle.fill"
        }
    }

    private func color(for status: CSVImportRow.Status) -> Color {
        switch status {
        case .ready: .green
        case .duplicate: .orange
        case .error: .red
        }
    }

    private func runImport() {
        if model.performImport() {
            Haptics.success()
            if let n = model.importedCount {
                toast.showSuccess(String(localized: "Imported ^[\(n) birth](inflect: true)", bundle: .module))
            }
            dismiss()
        } else {
            Haptics.error()
        }
    }
}
#endif
