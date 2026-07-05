//
//  DeliveryEntryView.swift
//  StorkFeatureDeliveries
//
//  The new/edit delivery form: details, babies, tags, and notes. Saving routes through
//  `DeliveryEntryModel` and reports any crossed milestone via `onFinish`.
//

#if os(iOS)
import SwiftUI
import StorkCore
import StorkDesignSystem

public struct DeliveryEntryView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage(AppStorageKeys.useMetricUnits) private var useMetricUnits: Bool = false

    @Bindable private var model: DeliveryEntryModel
    private let onFinish: (MilestoneCelebration?) -> Void

    @State private var editingBaby: Baby?
    @State private var saveErrorMessage: String?

    public init(model: DeliveryEntryModel, onFinish: @escaping (MilestoneCelebration?) -> Void = { _ in }) {
        self.model = model
        self.onFinish = onFinish
    }

    public var body: some View {
        NavigationStack {
            Form {
                DetailsSection(model: model)
                BabiesSection(model: model, editingBaby: $editingBaby)
                TagsSection(model: model)
                NotesSection(model: model)
            }
            .navigationTitle(model.isEditing ? "Edit Delivery" : "New Delivery")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .keyboardShortcut(.escape, modifiers: [])
                        .hoverEffect(.highlight)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(model.isEditing ? "Save" : "Finish") {
                        do {
                            let celebration = try model.save()
                            onFinish(celebration)
                            dismiss()
                        } catch {
                            // Keep the sheet open — the user's entries are still intact.
                            saveErrorMessage = error.localizedDescription
                        }
                    }
                    .disabled(!model.canFinish)
                    .keyboardShortcut(.return, modifiers: .command)
                    .hoverEffect(.highlight)
                }
            }
            .sheet(isPresented: $model.showingBabySheet) {
                BabyEntrySheet(model: model, useMetricUnits: useMetricUnits, editingBaby: editingBaby)
                    .interactiveDismissDisabled()
                    .onDisappear { editingBaby = nil }
            }
            .sheet(isPresented: $model.showingTagSheet) {
                TagPickerSheet(model: model)
                    .presentationDetents([.medium, .large])
            }
            .alert(
                "Couldn't Save Delivery",
                isPresented: Binding(
                    get: { saveErrorMessage != nil },
                    set: { if !$0 { saveErrorMessage = nil } }
                )
            ) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(saveErrorMessage ?? String(localized: "An unknown error occurred. Please try again."))
            }
        }
    }

    // MARK: - Sections

    private struct DetailsSection: View {
        @Bindable var model: DeliveryEntryModel

        var body: some View {
            Section("Details") {
                DatePicker("Date", selection: $model.date, in: model.dateRange, displayedComponents: [.date, .hourAndMinute])
                    .datePickerStyle(.compact)
                    .disabled(model.isEditing)
                    .onChange(of: model.date) { _, _ in model.clampDate() }
                    .accessibilityLabel("Delivery date and time")

                Picker("Delivery Method", selection: $model.deliveryMethod) {
                    ForEach(DeliveryMethod.allCases, id: \.self) { method in
                        Text(method.description).tag(method)
                    }
                }
                .pickerStyle(.segmented)
                .accessibilityLabel("Delivery method")

                Toggle("Epidural Used", isOn: $model.epiduralUsed)
                    .tint(.red)
                    .accessibilityLabel("Epidural used")
            }
        }
    }

    private struct BabiesSection: View {
        @Bindable var model: DeliveryEntryModel
        @Binding var editingBaby: Baby?
        @AppStorage(AppStorageKeys.useMetricUnits) private var useMetricUnits: Bool = false

        var body: some View {
            Section {
                ForEach(model.babies) { baby in
                    BabyRowView(
                        baby: baby,
                        useMetricUnits: useMetricUnits,
                        onEdit: {
                            editingBaby = baby
                            model.showingBabySheet = true
                        },
                        onDelete: { model.removeBaby(id: baby.id) }
                    )
                    .padding(.vertical, 4)
                }

                Button {
                    editingBaby = nil
                    model.showingBabySheet = true
                } label: {
                    Label("Add Baby", systemImage: "plus")
                }
                .tint(.storkBlue)
                .listItemTint(.storkBlue)
                .hoverEffect(.highlight)
            } header: {
                Text("Babies")
            } footer: {
                if model.babies.isEmpty {
                    Text("At least one baby is required.").foregroundStyle(.red)
                }
            }
        }
    }

    private struct TagsSection: View {
        @Bindable var model: DeliveryEntryModel

        var body: some View {
            Section {
                if !model.selectedTags.isEmpty {
                    FlowLayout(spacing: 8) {
                        ForEach(model.selectedTags) { tag in
                            TagChipView(tag: tag) { model.removeTag(id: tag.id) }
                        }
                    }
                    .padding(.vertical, 4)
                }

                Button {
                    model.showingTagSheet = true
                } label: {
                    Label("Add Tags", systemImage: "tag")
                }
                .tint(.storkPurple)
                .listItemTint(.storkPurple)
                .hoverEffect(.highlight)
            } header: {
                Text("Tags")
            } footer: {
                Text("Examples: \"Teaching Moment\", \"First Solo\", \"Night Shift\". Do not include patient information.")
            }
        }
    }

    private struct NotesSection: View {
        @Bindable var model: DeliveryEntryModel

        var body: some View {
            Section {
                TextField("Add a personal note...", text: $model.notes, axis: .vertical)
                    .lineLimit(3...6)
                    .accessibilityLabel("Delivery notes")
            } header: {
                Text("Notes")
            } footer: {
                Text("Private notes for memorable deliveries. No PHI - just personal memories like \"twins on Christmas!\"")
            }
        }
    }
}
#endif
