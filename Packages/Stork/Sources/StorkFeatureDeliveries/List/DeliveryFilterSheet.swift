//
//  DeliveryFilterSheet.swift
//  StorkFeatureDeliveries
//
//  Edits a `DeliveryFilter`: date range, baby count, method, epidural, tags, and notes.
//  Tags are passed in (loaded through the repository) rather than queried directly.
//

#if os(iOS)
import SwiftUI
import StorkCore
import StorkDesignSystem

struct DeliveryFilterSheet: View {
    @Environment(\.dismiss) private var dismiss

    @Binding var filter: DeliveryFilter
    let availableTags: [DeliveryTag]

    @State private var tempFilter: DeliveryFilter
    @State private var startDate: Date
    @State private var endDate: Date
    @State private var isDateRangeEnabled: Bool

    init(filter: Binding<DeliveryFilter>, availableTags: [DeliveryTag]) {
        _filter = filter
        self.availableTags = availableTags
        _tempFilter = State(initialValue: filter.wrappedValue)
        if let range = filter.wrappedValue.dateRange {
            _startDate = State(initialValue: range.lowerBound)
            _endDate = State(initialValue: range.upperBound)
            _isDateRangeEnabled = State(initialValue: true)
        } else {
            let now = Date()
            _startDate = State(initialValue: Calendar.current.date(byAdding: .month, value: -1, to: now) ?? now)
            _endDate = State(initialValue: now)
            _isDateRangeEnabled = State(initialValue: false)
        }
    }

    // MARK: - Bindings

    private var babyCountBinding: Binding<Int> {
        Binding(
            get: { tempFilter.babyCount ?? 0 },
            set: { tempFilter.babyCount = $0 > 0 ? $0 : nil }
        )
    }

    private func deliveryMethodBinding(for method: DeliveryMethod) -> Binding<Bool> {
        Binding(
            get: { tempFilter.deliveryMethod.contains(method) },
            set: { isOn in
                if isOn { tempFilter.deliveryMethod.insert(method) }
                else { tempFilter.deliveryMethod.remove(method) }
            }
        )
    }

    private func tagBinding(for tag: DeliveryTag) -> Binding<Bool> {
        Binding(
            get: { tempFilter.selectedTagIds.contains(tag.id) },
            set: { isOn in
                if isOn { tempFilter.selectedTagIds.insert(tag.id) }
                else { tempFilter.selectedTagIds.remove(tag.id) }
            }
        )
    }

    private var babyCountDisplayText: String {
        if let count = tempFilter.babyCount, count > 0 {
            return String(localized: "^[\(count) baby](inflect: true)", bundle: .module)
        }
        return String(localized: "Any number of babies", bundle: .module)
    }

    private func applyFilters() {
        tempFilter.dateRange = isDateRangeEnabled ? (startDate...endDate) : nil
        filter = tempFilter
        dismiss()
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(String(localized: "Date Range", bundle: .module)) {
                    Toggle(String(localized: "Filter by Date Range", bundle: .module), isOn: $isDateRangeEnabled)
                    if isDateRangeEnabled {
                        DatePicker(String(localized: "Start Date", bundle: .module), selection: $startDate, displayedComponents: [.date])
                        DatePicker(String(localized: "End Date", bundle: .module), selection: $endDate, displayedComponents: [.date])
                    }
                }

                Section(String(localized: "Baby Count", bundle: .module)) {
                    Stepper(value: babyCountBinding, in: 0...10) {
                        Text(babyCountDisplayText)
                    }
                }

                Section(String(localized: "Delivery Method", bundle: .module)) {
                    ForEach(DeliveryMethod.allCases, id: \.self) { method in
                        Toggle(method.displayName, isOn: deliveryMethodBinding(for: method))
                    }
                }

                Section(String(localized: "Epidural", bundle: .module)) {
                    Toggle(String(localized: "Epidural Used Only", bundle: .module), isOn: $tempFilter.epiduralUsedOnly)
                        .tint(.red)
                }

                if !availableTags.isEmpty {
                    Section {
                        ForEach(availableTags) { tag in
                            Toggle(isOn: tagBinding(for: tag)) {
                                HStack(spacing: 8) {
                                    Circle().fill(tag.color).frame(width: 12, height: 12)
                                    Text(tag.name)
                                }
                            }
                            .tint(.storkPurple)
                        }
                    } header: {
                        Text("Tags", bundle: .module)
                    } footer: {
                        Text("Shows deliveries with ANY of the selected tags", bundle: .module)
                    }
                }

                Section(String(localized: "Notes", bundle: .module)) {
                    Toggle(String(localized: "Has Notes", bundle: .module), isOn: $tempFilter.hasNotesOnly)
                        .tint(.storkOrange)
                }
            }
            .navigationTitle(Text("Filter Deliveries", bundle: .module))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "Cancel", bundle: .module)) { dismiss() }
                        .keyboardShortcut(.escape, modifiers: [])
                        .hoverEffect(.highlight)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(String(localized: "Reset", bundle: .module)) {
                        let searchText = tempFilter.searchText
                        tempFilter = DeliveryFilter()
                        tempFilter.searchText = searchText
                        isDateRangeEnabled = false
                    }
                    .disabled({
                        var withoutSearch = tempFilter
                        withoutSearch.searchText = ""
                        return withoutSearch.isEmpty && !isDateRangeEnabled
                    }())
                    .hoverEffect(.highlight)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Apply", action: applyFilters)
                        .disabled(isDateRangeEnabled && endDate < startDate)
                        .keyboardShortcut(.return, modifiers: .command)
                        .hoverEffect(.highlight)
                }
            }
        }
    }
}

#if DEBUG
#Preview("Delivery Filter Sheet") {
    DeliveryFilterSheet(filter: .constant(DeliveryFilter()), availableTags: [])
}
#endif
#endif
