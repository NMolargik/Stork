//
//  BabyEntrySheet.swift
//  StorkFeatureDeliveries
//
//  Add/edit form for a single baby; converts display units back to stored imperial on save.
//

#if os(iOS)
import SwiftUI
import StorkCore

struct BabyEntrySheet: View {
    @Environment(\.dismiss) private var dismiss

    let model: DeliveryEntryModel
    let useMetricUnits: Bool
    @State private var entry: DeliveryEntryModel.BabyEntry

    init(model: DeliveryEntryModel, useMetricUnits: Bool, editingBaby: Baby? = nil) {
        self.model = model
        self.useMetricUnits = useMetricUnits
        _entry = State(initialValue: DeliveryEntryModel.BabyEntry(
            birthday: model.date,
            baby: editingBaby,
            useMetricUnits: useMetricUnits
        ))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Sex") {
                    Picker("Sex", selection: $entry.sex) {
                        ForEach(Sex.allCases) { sex in
                            Text(sex.rawValue.capitalized).tag(sex)
                        }
                    }
                    .pickerStyle(.segmented)
                    .accessibilityLabel("Baby sex")
                }

                Section("Weight") {
                    HStack {
                        TextField(useMetricUnits ? "Weight (kg)" : "Weight (oz)", value: $entry.weight, format: .number)
                            .keyboardType(.decimalPad)
                            .accessibilityLabel(useMetricUnits ? "Weight in kilograms" : "Weight in ounces")
                        Text(useMetricUnits ? "kg" : "oz").accessibilityHidden(true)
                    }
                }

                Section("Height") {
                    HStack {
                        TextField(useMetricUnits ? "Height (cm)" : "Height (in)", value: $entry.height, format: .number)
                            .keyboardType(.decimalPad)
                            .accessibilityLabel(useMetricUnits ? "Height in centimeters" : "Height in inches")
                        Text(useMetricUnits ? "cm" : "in").accessibilityHidden(true)
                    }
                }

                Section("Additional Info") {
                    Toggle("NICU Stay", isOn: $entry.nicuStay)
                    Toggle("Nurse Catch", isOn: $entry.nurseCatch)
                }
            }
            .navigationTitle(entry.id == nil ? "Add Baby" : "Edit Baby")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(entry.id == nil ? "Add" : "Save") {
                        model.upsert(entry.makeBaby(useMetricUnits: useMetricUnits))
                        dismiss()
                    }
                    .disabled(!entry.isValid)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
#endif
