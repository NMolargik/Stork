import SwiftUI
import SwiftData

struct DeliveryEditFormView: View {
    @Environment(DeliveryManager.self) private var deliveryManager: DeliveryManager
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @AppStorage(AppStorageKeys.useMetricUnits) private var useMetricUnits: Bool = false

    @Bindable var delivery: Delivery

    @State private var showBabySheet = false
    @State private var editingBaby: Baby? = nil
    @State private var showTagSheet = false
    @State private var editedNotes: String = ""
    @State private var editedTags: [DeliveryTag] = []

    init(delivery: Delivery) {
        self.delivery = delivery
        _editedNotes = State(initialValue: delivery.notes ?? "")
        _editedTags = State(initialValue: delivery.tags ?? [])
    }

    // MARK: - Extracted Bindings

    private var deliveryMethodBinding: Binding<DeliveryMethod> {
        Binding(
            get: { delivery.deliveryMethod },
            set: { delivery.deliveryMethod = $0 }
        )
    }

    private var epiduralBinding: Binding<Bool> {
        Binding(
            get: { delivery.epiduralUsed },
            set: { delivery.epiduralUsed = $0 }
        )
    }

    // MARK: - Actions

    private func deleteBabies(_ indexSet: IndexSet) {
        var current = delivery.babies ?? []
        for index in indexSet.sorted(by: >) {
            if index >= 0 && index < current.count {
                let baby = current[index]
                baby.delivery = nil
                current.remove(at: index)
            }
        }
        delivery.babies = current
        delivery.babyCount = current.count
        do { try modelContext.save() } catch { print("Save failed: \(error)") }
        Task { await deliveryManager.refresh() }
    }

    private func saveDelivery() {
        for baby in delivery.babies ?? [] { baby.delivery = delivery }
        delivery.babyCount = delivery.babies?.count ?? 0
        delivery.notes = editedNotes.isEmpty ? nil : editedNotes
        delivery.tags = editedTags
        do { try modelContext.save() } catch { print("Save failed: \(error)") }
        Task { await deliveryManager.refresh() }
        dismiss()
    }

    private func handleBabySave(_ updated: BabyDraft) {
        var list = delivery.babies ?? []
        if let existing = editingBaby, let idx = list.firstIndex(where: { $0.id == existing.id }) {
            list[idx].sex = updated.sex
            list[idx].weight = updated.weight
            list[idx].height = updated.height
            list[idx].nicuStay = updated.nicuStay
            list[idx].nurseCatch = updated.nurseCatch
            list[idx].birthday = updated.birthday
        } else {
            let new = Baby(
                birthday: updated.birthday,
                height: updated.height,
                weight: updated.weight,
                nurseCatch: updated.nurseCatch,
                nicuStay: updated.nicuStay,
                sex: updated.sex,
                delivery: delivery
            )
            list.append(new)
        }
        for b in list { b.delivery = delivery }
        delivery.babies = list
        delivery.babyCount = list.count
        do { try modelContext.save() } catch { print("Save failed: \(error)") }
        Task { await deliveryManager.refresh() }
    }

    private func removeTag(at index: Int) {
        editedTags.remove(at: index)
    }

    // MARK: - View Sections

    @ViewBuilder
    private var deliveryDetailsSection: some View {
        Section("Delivery Details") {
            Picker("Delivery Method", selection: deliveryMethodBinding) {
                ForEach(DeliveryMethod.allCases, id: \.self) { method in
                    Text(method.description).tag(method)
                }
            }
            .pickerStyle(.segmented)

            Toggle("Epidural Used", isOn: epiduralBinding)
                .tint(.red)
        }
    }

    @ViewBuilder
    private var babiesSection: some View {
        Section("Babies") {
            babiesList
            addBabyButton
        }
    }

    @ViewBuilder
    private var babiesList: some View {
        if let babies = delivery.babies, !babies.isEmpty {
            ForEach(babies) { baby in
                babyRow(baby)
            }
            .onDelete(perform: deleteBabies)
        } else {
            Text("No babies recorded.")
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private func babyRow(_ baby: Baby) -> some View {
        HStack {
            Image(systemName: "figure.child")
                .foregroundStyle(baby.sex.color)
            Text(baby.sex.displayName)
            Spacer()
            Text("\(UnitConversion.weightDisplay(baby.weight, useMetric: useMetricUnits)), \(UnitConversion.heightDisplay(baby.height, useMetric: useMetricUnits))")
                .foregroundStyle(.secondary)
            Button {
                editingBaby = baby
                showBabySheet = true
            } label: {
                Image(systemName: "pencil")
            }
            .buttonStyle(.borderedProminent)
            .tint(.storkOrange)
            .foregroundColor(.white)
        }
    }

    @ViewBuilder
    private var addBabyButton: some View {
        Button {
            editingBaby = nil
            showBabySheet = true
        } label: {
            Label("Add A Baby", systemImage: "plus")
        }
        .buttonStyle(.borderedProminent)
        .tint(.storkOrange)
        .foregroundColor(.white)
    }

    @ViewBuilder
    private var tagsSection: some View {
        Section("Tags") {
            if !editedTags.isEmpty {
                FlowLayout(spacing: 8) {
                    ForEach(editedTags) { tag in
                        TagChipView(tag: tag) {
                            if let index = editedTags.firstIndex(where: { $0.id == tag.id }) {
                                removeTag(at: index)
                            }
                        }
                    }
                }
                .padding(.vertical, 4)
            } else {
                Text("No tags added.")
                    .foregroundStyle(.secondary)
            }

            Button {
                showTagSheet = true
            } label: {
                Label("Manage Tags", systemImage: "tag")
            }
            .buttonStyle(.borderedProminent)
            .tint(.storkPurple)
            .foregroundColor(.white)
        }
    }

    @ViewBuilder
    private var notesSection: some View {
        Section {
            TextField("Add a personal note...", text: $editedNotes, axis: .vertical)
                .lineLimit(3...6)
        } header: {
            Text("Notes")
        } footer: {
            Text("Private notes for memorable deliveries. No PHI.")
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                deliveryDetailsSection
                babiesSection
                tagsSection
                notesSection
            }
            .navigationTitle("Edit Delivery")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(.storkOrange)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: saveDelivery)
                }
            }
            .sheet(isPresented: $showTagSheet) {
                TagPickerSheet(selectedTags: $editedTags)
                    .presentationDetents([.medium, .large])
            }
            .sheet(isPresented: $showBabySheet) {
                BabyEditSheet(
                    baby: editingBaby,
                    onSave: handleBabySave,
                    onCancel: {}
                )
                .interactiveDismissDisabled()
            }
        }
    }
}

private struct BabyDraft {
    var sex: Sex
    var weight: Double
    var height: Double
    var nicuStay: Bool
    var nurseCatch: Bool
    var birthday: Date
}

private struct BabyEditSheet: View {
    @Environment(\.dismiss) private var dismiss

    @AppStorage(AppStorageKeys.useMetricUnits) private var useMetricUnits: Bool = false

    var baby: Baby?
    var onSave: (BabyDraft) -> Void
    var onCancel: () -> Void

    @State private var draft: BabyDraft

    init(baby: Baby?, onSave: @escaping (BabyDraft) -> Void, onCancel: @escaping () -> Void) {
        self.baby = baby
        self.onSave = onSave
        self.onCancel = onCancel
        if let b = baby {
            _draft = State(initialValue: BabyDraft(sex: b.sex, weight: b.weight, height: b.height, nicuStay: b.nicuStay, nurseCatch: b.nurseCatch, birthday: b.birthday))
        } else {
            _draft = State(initialValue: BabyDraft(sex: .male, weight: 121.6, height: 19.0, nicuStay: false, nurseCatch: false, birthday: Date()))
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Sex") {
                    Picker("Sex", selection: $draft.sex) {
                        ForEach(Sex.allCases, id: \.self) { sex in
                            Text(sex.displayName).tag(sex)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                Section("Weight") {
                    HStack {
                        TextField(useMetricUnits ? "Weight (g)" : "Weight (oz)",
                                  value: Binding<Double>(
                                    get: { useMetricUnits ? draft.weight * 28.349523125 : draft.weight },
                                    set: { newVal in draft.weight = useMetricUnits ? newVal / 28.349523125 : newVal }
                                  ),
                                  format: .number)
                        .keyboardType(.decimalPad)
                        
                        Text(useMetricUnits ? "g" : "oz")
                    }
                }
                Section("Height") {
                    HStack {
                        TextField(useMetricUnits ? "Height (cm)" : "Height (in)",
                                  value: Binding<Double>(
                                    get: { useMetricUnits ? draft.height * 2.54 : draft.height },
                                    set: { newVal in draft.height = useMetricUnits ? newVal / 2.54 : newVal }
                                  ),
                                  format: .number)
                        .keyboardType(.decimalPad)
                        Text(useMetricUnits ? "cm" : "in")
                    }
                }
                Section("Additional Info") {
                    Toggle("NICU Stay", isOn: $draft.nicuStay)
                        .tint(.storkPurple)
                    Toggle("Nurse Catch", isOn: $draft.nurseCatch)
                        .tint(.red)
                }
            }
            .navigationTitle(baby == nil ? "Add Baby" : "Edit Baby")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { onCancel(); dismiss() }
                        .foregroundStyle(.storkOrange)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { onSave(draft); dismiss() }
                        .disabled(!isValid)
                }
            }
        }
    }

    private var isValid: Bool { draft.weight > 0 && draft.height > 0 }
}

#Preview {
    let container: ModelContainer = {
        let schema = Schema([Delivery.self, Baby.self])
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        return try! ModelContainer(for: schema, configurations: [configuration])
    }()
    let context = ModelContext(container)
    let d = Delivery.sample()
    return DeliveryEditFormView(delivery: d)
        .environment(DeliveryManager(context: context))
}
