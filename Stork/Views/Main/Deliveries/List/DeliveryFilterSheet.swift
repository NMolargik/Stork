// DeliveryFilterView.swift
import SwiftUI

struct DeliveryFilterSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    @Binding var filter: DeliveryFilter
    
    @State private var tempFilter: DeliveryFilter // Temporary filter for editing
    @State private var startDate: Date
    @State private var endDate: Date
    @State private var isDateRangeEnabled: Bool
    
    init(filter: Binding<DeliveryFilter>) {
        self._filter = filter
        self._tempFilter = State(initialValue: filter.wrappedValue)
        if let range = filter.wrappedValue.dateRange {
            self._startDate = State(initialValue: range.lowerBound)
            self._endDate = State(initialValue: range.upperBound)
            self._isDateRangeEnabled = State(initialValue: true)
        } else {
            let now = Date()
            self._startDate = State(initialValue: Calendar.current.date(byAdding: .month, value: -1, to: now) ?? now)
            self._endDate = State(initialValue: now)
            self._isDateRangeEnabled = State(initialValue: false)
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                // Date Range
                Section(header: Text("Date Range")) {
                    Toggle("Filter by Date Range", isOn: $isDateRangeEnabled)
                    if isDateRangeEnabled {
                        DatePicker("Start Date", selection: $startDate, displayedComponents: [.date])
                        DatePicker("End Date", selection: $endDate, displayedComponents: [.date])
                    }
                }
                
                // Baby Count
                Section(header: Text("Baby Count")) {
                    Stepper(
                        value: Binding(
                            get: { tempFilter.babyCount ?? 0 },
                            set: { tempFilter.babyCount = $0 > 0 ? $0 : nil }
                        ),
                        in: 0...10
                    ) {
                        Text({
                            if let count = tempFilter.babyCount, count > 0 {
                                return "\(count) \(count == 1 ? "baby" : "babies")"
                            } else {
                                return "Any number of babies"
                            }
                        }())
                    }
                }
                
                // Delivery Method
                Section(header: Text("Delivery Method")) {
                    ForEach(DeliveryMethod.allCases, id: \.self) { method in
                        Toggle(method.rawValue.capitalized, isOn: Binding(
                            get: { tempFilter.deliveryMethod.contains(method) },
                            set: { isOn in
                                if isOn {
                                    tempFilter.deliveryMethod.insert(method)
                                } else {
                                    tempFilter.deliveryMethod.remove(method)
                                }
                            }
                        ))
                    }
                }
                
                // Epidural Used
                Section(header: Text("Epidural")) {
                    Toggle("Epidural Used Only", isOn: $tempFilter.epiduralUsedOnly)
                        .tint(.red)
                }
            }
            .navigationTitle("Filter Deliveries")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(.storkOrange)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Apply") {
                        // Apply date range only if enabled
                        tempFilter.dateRange = isDateRangeEnabled ? (startDate...endDate) : nil
                        filter = tempFilter
                        dismiss()
                    }
                    .disabled(isDateRangeEnabled && endDate < startDate)
                }
            }
        }
    }
}

#Preview("Delivery Filter Sheet") {
    DeliveryFilterSheet(filter: .constant(DeliveryFilter()))
}

