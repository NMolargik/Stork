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
                if model.supportsWeather {
                    WeatherSection(model: model, useMetricUnits: useMetricUnits)
                }
                BabiesSection(model: model, editingBaby: $editingBaby)
                TagsSection(model: model)
                NotesSection(model: model)
            }
            .navigationTitle(model.isEditing ? "Edit Delivery" : "New Delivery")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "Cancel", bundle: .module)) { dismiss() }
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
                Button(String(localized: "OK", bundle: .module), role: .cancel) {}
            } message: {
                Text(saveErrorMessage ?? String(localized: "An unknown error occurred. Please try again.", bundle: .module))
            }
        }
    }

    // MARK: - Sections

    private struct DetailsSection: View {
        @Bindable var model: DeliveryEntryModel

        var body: some View {
            Section(String(localized: "Details", bundle: .module)) {
                DatePicker(String(localized: "Date", bundle: .module), selection: $model.date, in: ...model.dateUpperBound, displayedComponents: [.date, .hourAndMinute])
                    .datePickerStyle(.compact)
                    .disabled(model.isEditing)
                    .onChange(of: model.date) { _, _ in model.clampDate() }
                    .accessibilityLabel(Text("Delivery date and time", bundle: .module))

                Picker(String(localized: "Delivery Method", bundle: .module), selection: $model.deliveryMethod) {
                    ForEach(DeliveryMethod.allCases, id: \.self) { method in
                        Text(method.description).tag(method)
                    }
                }
                .pickerStyle(.segmented)
                .accessibilityLabel(Text("Delivery method", bundle: .module))

                Toggle(String(localized: "Epidural Used", bundle: .module), isOn: $model.epiduralUsed)
                    .tint(.red)
                    .accessibilityLabel(Text("Epidural used", bundle: .module))
            }
        }
    }

    /// Stork Pro: attach the conditions outside to this delivery. Free users see the
    /// locked row and reach the paywall in context; location is requested only here.
    private struct WeatherSection: View {
        @Bindable var model: DeliveryEntryModel
        let useMetricUnits: Bool
        @Environment(\.requestProUpgrade) private var requestProUpgrade

        var body: some View {
            Section {
                if !model.isProUnlocked {
                    Button {
                        Haptics.lightImpact()
                        requestProUpgrade(.weatherAtDelivery)
                    } label: {
                        HStack {
                            Label(String(localized: "Add Weather Snapshot", bundle: .module), systemImage: "cloud.sun.fill")
                            Spacer()
                            ProBadge()
                        }
                    }
                    .hoverEffect(.highlight)
                } else if let weather = model.weather {
                    HStack(spacing: 12) {
                        Image(systemName: weather.symbolName)
                            .symbolRenderingMode(.multicolor)
                            .font(.title2)
                            .accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(weather.temperatureString(useMetric: useMetricUnits)).font(.headline)
                            Text(weather.conditionDisplayName).font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Button(role: .destructive) {
                            Haptics.lightImpact()
                            model.removeWeather()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(.secondary)
                        .accessibilityLabel(Text("Remove weather snapshot", bundle: .module))
                    }
                    .accessibilityElement(children: .combine)
                } else {
                    Button {
                        Haptics.lightImpact()
                        Task { await model.captureWeather() }
                    } label: {
                        HStack {
                            Label(String(localized: "Add Weather Snapshot", bundle: .module), systemImage: "cloud.sun.fill")
                            Spacer()
                            if model.isCapturingWeather { ProgressView().controlSize(.small) }
                        }
                    }
                    .disabled(!model.canCaptureWeather || model.isCapturingWeather)
                    .tint(.storkBlue)
                    .listItemTint(.storkBlue)
                    .hoverEffect(.highlight)
                }
            } header: {
                Text("Weather", bundle: .module)
            } footer: {
                if let message = model.weatherErrorMessage {
                    Text(message).foregroundStyle(.red)
                } else if model.isProUnlocked && !model.isDateRecentEnoughForWeather && model.weather == nil {
                    Text("Weather snapshots use current conditions, so they're available for deliveries within the last 24 hours.", bundle: .module)
                } else {
                    Text("Uses your location once, only when you tap. Nothing about where you work is stored — just the temperature and sky.", bundle: .module)
                }
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
                    Label(String(localized: "Add Baby", bundle: .module), systemImage: "plus")
                }
                .tint(.storkBlue)
                .listItemTint(.storkBlue)
                .hoverEffect(.highlight)
            } header: {
                Text("Babies", bundle: .module)
            } footer: {
                if model.babies.isEmpty {
                    Text("At least one baby is required.", bundle: .module).foregroundStyle(.red)
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
                    Label(String(localized: "Add Tags", bundle: .module), systemImage: "tag")
                }
                .tint(.storkPurple)
                .listItemTint(.storkPurple)
                .hoverEffect(.highlight)
            } header: {
                Text("Tags", bundle: .module)
            } footer: {
                Text("Examples: \"Teaching Moment\", \"First Solo\", \"Night Shift\". Do not include patient information.", bundle: .module)
            }
        }
    }

    private struct NotesSection: View {
        @Bindable var model: DeliveryEntryModel

        var body: some View {
            Section {
                TextField(String(localized: "Add a personal note...", bundle: .module), text: $model.notes, axis: .vertical)
                    .lineLimit(3...6)
                    .accessibilityLabel(Text("Delivery notes", bundle: .module))
            } header: {
                Text("Notes", bundle: .module)
            } footer: {
                Text("Private notes for memorable deliveries. No PHI - just personal memories like \"twins on Christmas!\"", bundle: .module)
            }
        }
    }
}
#endif
