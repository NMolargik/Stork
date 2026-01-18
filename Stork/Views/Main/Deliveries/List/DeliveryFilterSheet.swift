// DeliveryFilterView.swift
import SwiftUI
import SwiftData

struct DeliveryFilterSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \DeliveryTag.name) private var allTags: [DeliveryTag]

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

    // MARK: - Extracted Bindings

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
                if isOn {
                    tempFilter.deliveryMethod.insert(method)
                } else {
                    tempFilter.deliveryMethod.remove(method)
                }
            }
        )
    }

    private func tagBinding(for tag: DeliveryTag) -> Binding<Bool> {
        Binding(
            get: { tempFilter.selectedTagIds.contains(tag.id) },
            set: { isOn in
                if isOn {
                    tempFilter.selectedTagIds.insert(tag.id)
                } else {
                    tempFilter.selectedTagIds.remove(tag.id)
                }
            }
        )
    }

    private var babyCountDisplayText: String {
        if let count = tempFilter.babyCount, count > 0 {
            return "\(count) \(count == 1 ? "baby" : "babies")"
        } else {
            return "Any number of babies"
        }
    }

    private func applyFilters() {
        tempFilter.dateRange = isDateRangeEnabled ? (startDate...endDate) : nil
        filter = tempFilter
        dismiss()
    }

    // MARK: - View Sections

    @ViewBuilder
    private var dateRangeSection: some View {
        Section {
            Toggle("Filter by Date Range", isOn: $isDateRangeEnabled)
                .accessibilityLabel("Filter by date range")
                .accessibilityHint("Enable to filter deliveries within a specific date range")
            if isDateRangeEnabled {
                DatePicker("Start Date", selection: $startDate, displayedComponents: [.date])
                    .accessibilityLabel("Start date")
                    .accessibilityHint("Select the beginning of the date range")
                DatePicker("End Date", selection: $endDate, displayedComponents: [.date])
                    .accessibilityLabel("End date")
                    .accessibilityHint("Select the end of the date range")
            }
        } header: {
            Text("Date Range")
        }
    }

    @ViewBuilder
    private var babyCountSection: some View {
        Section {
            Stepper(value: babyCountBinding, in: 0...10) {
                Text(babyCountDisplayText)
            }
            .accessibilityLabel("Baby count filter")
            .accessibilityValue(tempFilter.babyCount != nil ? "\(tempFilter.babyCount!) babies" : "Any number")
            .accessibilityHint("Adjust to filter by number of babies per delivery")
        } header: {
            Text("Baby Count")
        }
    }

    @ViewBuilder
    private var deliveryMethodSection: some View {
        Section {
            ForEach(DeliveryMethod.allCases, id: \.self) { method in
                Toggle(method.rawValue.capitalized, isOn: deliveryMethodBinding(for: method))
            }
        } header: {
            Text("Delivery Method")
        }
    }

    @ViewBuilder
    private var epiduralSection: some View {
        Section {
            Toggle("Epidural Used Only", isOn: $tempFilter.epiduralUsedOnly)
                .tint(.red)
                .accessibilityLabel("Epidural used only")
                .accessibilityHint("Enable to show only deliveries where epidural was used")
        } header: {
            Text("Epidural")
        }
    }

    @ViewBuilder
    private var tagsSection: some View {
        if !allTags.isEmpty {
            Section {
                ForEach(allTags) { tag in
                    Toggle(isOn: tagBinding(for: tag)) {
                        HStack(spacing: 8) {
                            Circle()
                                .fill(tag.color)
                                .frame(width: 12, height: 12)
                            Text(tag.name)
                        }
                    }
                    .tint(.storkPurple)
                }
            } header: {
                Text("Tags")
            } footer: {
                Text("Shows deliveries with ANY of the selected tags")
            }
        }
    }

    @ViewBuilder
    private var notesSection: some View {
        Section {
            Toggle("Has Notes", isOn: $tempFilter.hasNotesOnly)
                .tint(.storkOrange)
                .accessibilityLabel("Has notes")
                .accessibilityHint("Enable to show only deliveries that have personal notes")
        } header: {
            Text("Notes")
        }
    }

    var body: some View {
        NavigationView {
            Form {
                dateRangeSection
                babyCountSection
                deliveryMethodSection
                epiduralSection
                tagsSection
                notesSection
            }
            .navigationTitle("Filter Deliveries")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(.storkOrange)
                        .accessibilityLabel("Cancel")
                        .accessibilityHint("Discards filter changes")
                        .keyboardShortcut(.escape, modifiers: [])
                        .hoverEffect(.highlight)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Apply", action: applyFilters)
                        .disabled(isDateRangeEnabled && endDate < startDate)
                        .accessibilityLabel("Apply filters")
                        .accessibilityHint(isDateRangeEnabled && endDate < startDate ? "End date must be after start date" : "Applies the selected filters to the delivery list")
                        .keyboardShortcut(.return, modifiers: .command)
                        .hoverEffect(.highlight)
                }
            }
        }
    }
}

#Preview("Delivery Filter Sheet") {
    DeliveryFilterSheet(filter: .constant(DeliveryFilter()))
}

