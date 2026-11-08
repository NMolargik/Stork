//
//  PastBirthsHubView.swift
//  StorkFeatureSettings
//
//  One entry point for everything that brings earlier births into Stork: approximate
//  yearly totals, or a CSV of individual births. Keeps Settings to a single "Past Births
//  & Import" row instead of one row per method.
//

#if os(iOS)
import SwiftUI
import StorkCore
import StorkDesignSystem

struct PastBirthsHubView: View {
    var model: SettingsModel

    var body: some View {
        List {
            Section {
                NavigationLink {
                    AddPastBirthsView(model: model.makeAddPastBirthsModel())
                } label: {
                    hubRow(title: "Add Past Births", detail: "Enter approximate totals for each year of your career.", systemImage: "calendar.badge.plus")
                }
                NavigationLink {
                    CSVImportView(model: model.makeCSVImportModel())
                } label: {
                    hubRow(title: "Import from CSV", detail: "Bring in individual births from a spreadsheet.", systemImage: "tablecells.badge.ellipsis")
                }
            } footer: {
                Text("Both are free. Estimated years count toward your totals but never appear in day, month or time statistics.", bundle: .module)
            }
        }
        .navigationTitle(Text("Past Births & Import", bundle: .module))
        .navigationBarTitleDisplayMode(.inline)
    }

    private func hubRow(title: LocalizedStringKey, detail: LocalizedStringKey, systemImage: String) -> some View {
        Label {
            VStack(alignment: .leading, spacing: 2) {
                Text(title, bundle: .module)
                Text(detail, bundle: .module).font(.caption).foregroundStyle(.secondary)
            }
        } icon: {
            Image(systemName: systemImage).foregroundStyle(.storkBlue)
        }
    }
}
#endif
