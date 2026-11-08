//
//  AddPastBirthsView.swift
//  StorkFeatureSettings
//
//  "Add Past Births": approximate totals per year (a range with an average, or year by
//  year) plus optional splits. Saved as clearly marked estimated summaries.
//

#if os(iOS)
import SwiftUI
import StorkCore
import StorkDesignSystem

struct AddPastBirthsView: View {
    @Bindable var model: AddPastBirthsModel
    @Environment(\.dismiss) private var dismiss
    @Environment(ToastManager.self) private var toast

    var body: some View {
        Form {
            yearsSection
            detailsSection
            summarySection
        }
        .navigationTitle(Text("Add Past Births", bundle: .module))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button(String(localized: "Add", bundle: .module)) { save() }
                    .buttonStyle(.borderedProminent)
                    .tint(.storkBlue)
                    .disabled(!model.canSave)
            }
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button(String(localized: "Done", bundle: .module)) {
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
            }
        }
    }

    private var yearsSection: some View {
        Section {
            Picker(selection: $model.mode) {
                Text("Year Range", bundle: .module).tag(AddPastBirthsModel.Mode.range)
                Text("Year by Year", bundle: .module).tag(AddPastBirthsModel.Mode.yearByYear)
            } label: {
                Text("Entry", bundle: .module)
            }
            .pickerStyle(.segmented)
            .listRowSeparator(.hidden)

            switch model.mode {
            case .range:
                yearPicker(String(localized: "From", bundle: .module), selection: $model.rangeStart)
                yearPicker(String(localized: "To", bundle: .module), selection: $model.rangeEnd)
                LabeledContent {
                    TextField(String(localized: "Births", bundle: .module), value: $model.averagePerYear, format: .number.grouping(.never))
                        .keyboardType(.numberPad).multilineTextAlignment(.trailing)
                } label: {
                    Text("Average per year", bundle: .module)
                }
            case .yearByYear:
                ForEach($model.rows) { $row in
                    HStack {
                        Picker(selection: $row.year) {
                            ForEach(model.selectableYears, id: \.self) { Text(String($0)).tag($0) }
                        } label: { Text("Year", bundle: .module) }
                        .labelsHidden()
                        Spacer()
                        TextField(String(localized: "Births", bundle: .module), value: $row.births, format: .number.grouping(.never))
                            .keyboardType(.numberPad).multilineTextAlignment(.trailing)
                            .frame(maxWidth: 110)
                    }
                }
                .onDelete { model.removeRows(at: $0) }
                Button { model.addRow() } label: {
                    Label(String(localized: "Add Year", bundle: .module), systemImage: "plus.circle")
                }
            }
        } header: {
            Text("Years", bundle: .module)
        } footer: {
            if model.issues.contains(where: { if case .yearOutOfRange = $0 { true } else { false } }) || (model.mode == .range && model.rangeStart > model.rangeEnd) {
                Text("Choose years from 1950 up to this year, with the start before the end.", bundle: .module).foregroundStyle(.red)
            } else if model.issues.contains(where: { if case .duplicateYear = $0 { true } else { false } }) {
                Text("Each year can only be listed once.", bundle: .module).foregroundStyle(.red)
            } else if model.issues.contains(where: { if case .birthsOutOfRange = $0 { true } else { false } }) {
                Text("Births per year must be between 0 and 2,000.", bundle: .module).foregroundStyle(.red)
            } else {
                Text("Round numbers are fine. A rough yearly average is enough.", bundle: .module)
            }
        }
    }

    private func yearPicker(_ title: String, selection: Binding<Int>) -> some View {
        Picker(title, selection: selection) {
            ForEach(model.selectableYears, id: \.self) { Text(String($0)).tag($0) }
        }
    }

    private var detailsSection: some View {
        Section {
            Picker(selection: $model.role) {
                Text("Not recorded", bundle: .module).tag(BirthRole?.none)
                ForEach(BirthRole.allCases) { Text($0.displayName).tag(BirthRole?.some($0)) }
            } label: { Text("Your role", bundle: .module) }
            percentField("Twins or more", detail: "% of births", value: $model.multiplesPercent)
            percentField("Losses", detail: "% of babies", value: $model.lossesPercent)
            percentField("Boys", detail: "% of live babies", value: $model.boysPercent)
        } header: {
            Text("Optional Details", bundle: .module)
        } footer: {
            Text("Leave a field blank to skip it. Without a boys percentage, these births stay out of the boy and girl split.", bundle: .module)
        }
    }

    private func percentField(_ title: LocalizedStringKey, detail: LocalizedStringKey, value: Binding<Int?>) -> some View {
        LabeledContent {
            HStack(spacing: 4) {
                TextField(String(localized: "Skip", bundle: .module), value: value, format: .number.grouping(.never))
                    .keyboardType(.numberPad).multilineTextAlignment(.trailing).frame(maxWidth: 70)
                Text(verbatim: "%").foregroundStyle(.secondary)
            }
        } label: {
            VStack(alignment: .leading, spacing: 0) {
                Text(title, bundle: .module)
                Text(detail, bundle: .module).font(.caption2).foregroundStyle(.secondary)
            }
        }
    }

    private var summarySection: some View {
        Section {
            let t = model.totals
            Label {
                if t.deliveries > 0 {
                    Text("About ^[\(t.deliveries) birth](inflect: true) and ^[\(t.babies) baby](inflect: true) across ^[\(t.years) year](inflect: true)", bundle: .module)
                } else {
                    Text("Enter a number of births to see the total.", bundle: .module)
                }
            } icon: {
                Image(systemName: "sparkles").foregroundStyle(.storkPurple)
            }
        } footer: {
            if model.lastError != nil {
                Text("Could not save. Please try again.", bundle: .module).foregroundStyle(.red)
            }
            Text("Saved as estimated. They count toward your totals, sex split and years, are marked Estimated in your list, and can be deleted any time.", bundle: .module)
        }
    }

    private func save() {
        if model.save() {
            Haptics.success()
            if let n = model.savedBirths {
                toast.showSuccess(String(localized: "Added ^[\(n) estimated birth](inflect: true)", bundle: .module))
            }
            dismiss()
        } else {
            Haptics.error()
        }
    }
}
#endif
