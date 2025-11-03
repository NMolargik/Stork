import Foundation
import SwiftUI

extension DeliveryEntryView {
    @Observable
    class ViewModel {
        var date: Date
        var deliveryMethod: DeliveryMethod
        var epiduralUsed: Bool
        var babies: [Baby]
        var showingBabySheet: Bool = false
        var selectedScene: UIWindowScene?
        
        init(existingDelivery: Delivery? = nil) {
            if let delivery = existingDelivery {
                self.date = delivery.date
                self.deliveryMethod = delivery.deliveryMethod
                self.epiduralUsed = delivery.epiduralUsed
                self.babies = delivery.babies ?? []
            } else {
                self.date = Date()
                self.deliveryMethod = .vaginal
                self.epiduralUsed = true
                self.babies = []
            }
        }
        
        var dateRange: ClosedRange<Date> {
            let calendar = Calendar.current
            let lower = calendar.date(byAdding: .day, value: -3, to: Date()) ?? Date()
            let upper = Date()
            return lower...upper
        }
        
        var canFinish: Bool {
            !babies.isEmpty && dateRange.contains(date)
        }
        
        func clampDate() {
            if date < dateRange.lowerBound {
                date = dateRange.lowerBound
            } else if date > dateRange.upperBound {
                date = dateRange.upperBound
            }
        }
        
        struct BabyEntry {
            var id: UUID?
            var sex: Sex = .male
            var weight: Double
            var height: Double
            var nurseCatch: Bool = false
            var nicuStay: Bool = false
            var birthday: Date
            
            init(birthday: Date, baby: Baby? = nil, useMetricUnits: Bool = false) {
                self.birthday = birthday
                if let baby = baby {
                    self.id = baby.id
                    self.sex = baby.sex
                    self.weight = useMetricUnits ? baby.weight / 35.27396 : baby.weight
                    self.height = useMetricUnits ? baby.height / 0.393701 : baby.height
                    self.nurseCatch = baby.nurseCatch
                    self.nicuStay = baby.nicuStay
                } else {
                    self.weight = useMetricUnits ? 3.45 : 121.6 // Approx 7lb 9.6oz
                    self.height = useMetricUnits ? 48.26 : 19.0 // Approx 19in
                }
            }
        }
    }
    
    struct BabyEntrySheet: View {
        @Binding var viewModel: ViewModel
        @AppStorage(AppStorageKeys.useMetricUnits) private var useMetricUnits: Bool = false
        @Environment(\.dismiss) private var dismiss
        @State private var entry: ViewModel.BabyEntry
        
        init(viewModel: Binding<ViewModel>, useMetricUnits: Bool, editingBaby: Baby? = nil) {
            self._viewModel = viewModel
            self.useMetricUnits = useMetricUnits
            self._entry = State(initialValue: ViewModel.BabyEntry(
                birthday: viewModel.wrappedValue.date,
                baby: editingBaby,
                useMetricUnits: useMetricUnits
            ))
        }
        
        var body: some View {
            NavigationStack {
                Form {
                    Section("Sex") {
                        Picker("Sex", selection: $entry.sex) {
                            ForEach(Sex.allCases, id: \.self) { sex in
                                Text(sex.rawValue.capitalized).tag(sex)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    
                    Section("Weight") {
                        if useMetricUnits {
                            HStack {
                                TextField("Weight (kg)", value: $entry.weight, format: .number)
                                    .keyboardType(.decimalPad)
                                Text("kg")
                            }
                        } else {
                            HStack {
                                TextField("Weight (oz)", value: $entry.weight, format: .number)
                                    .keyboardType(.decimalPad)
                                Text("oz")
                            }
                        }
                    }
                    
                    Section("Height") {
                        if useMetricUnits {
                            HStack {
                                TextField("Height (cm)", value: $entry.height, format: .number)
                                    .keyboardType(.decimalPad)
                                Text("cm")
                            }
                        } else {
                            HStack {
                                TextField("Height (in)", value: $entry.height, format: .number)
                                    .keyboardType(.decimalPad)
                                Text("in")
                            }
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
                            addOrUpdateBaby()
                            dismiss()
                        }
                        .disabled(!isValidEntry())
                    }
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            dismiss()
                        }
                        .foregroundStyle(.storkOrange)
                    }
                }
            }
        }
        
        private func isValidEntry() -> Bool {
            entry.weight > 0 && entry.height > 0
        }
        
        private func addOrUpdateBaby() {
            let weightInOunces: Double
            let heightInInches: Double
            
            if useMetricUnits {
                weightInOunces = entry.weight * 35.27396
                heightInInches = entry.height * 0.393701
            } else {
                weightInOunces = entry.weight
                heightInInches = entry.height
            }
            
            let baby = Baby()
            baby.id = entry.id ?? UUID()
            baby.sex = entry.sex
            baby.weight = weightInOunces
            baby.height = heightInInches
            baby.nicuStay = entry.nicuStay
            baby.nurseCatch = entry.nurseCatch
            baby.birthday = entry.birthday
            
            if let existingId = entry.id,
               let index = viewModel.babies.firstIndex(where: { $0.id == existingId }) {
                viewModel.babies[index] = baby
            } else {
                viewModel.babies.append(baby)
            }
        }
    }
}
