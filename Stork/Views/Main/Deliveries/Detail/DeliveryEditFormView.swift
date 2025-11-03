import SwiftUI
import SwiftData

struct DeliveryEditFormView: View {
    @Environment(DeliveryManager.self) private var deliveryManager: DeliveryManager
    @Environment(HospitalManager.self) private var hospitalManager: HospitalManager
    @Environment(UserManager.self) private var userManager: UserManager
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @AppStorage(AppStorageKeys.useMetricUnits) private var useMetricUnits: Bool = false

    @Bindable var delivery: Delivery

    @State private var showHospitalSheet = false
    @State private var showBabySheet = false
    @State private var editingBaby: Baby? = nil

    var body: some View {
        NavigationStack {
            Form {
                Section("Delivery Details") {
                    Picker("Delivery Method", selection: Binding(get: { delivery.deliveryMethod }, set: { delivery.deliveryMethod = $0 })) {
                        ForEach(DeliveryMethod.allCases, id: \.self) { method in
                            Text(method.description).tag(method)
                        }
                    }
                    .pickerStyle(.segmented)

                    Toggle("Epidural Used", isOn: Binding(get: { delivery.epiduralUsed }, set: { delivery.epiduralUsed = $0 }))
                        .tint(.red)
                }

                Section("Hospital") {
                    HStack(alignment: .top) {
                        if let hospitalId = delivery.hospitalId, let hospital = hospitalManager.hospitals.first(where: { $0.remoteId == hospitalId }) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(hospital.facilityName)
                                    .font(.headline)
                                    .lineLimit(2)
                                    .minimumScaleFactor(0.85)
                                Text("\(hospital.address), \(hospital.citytown), \(hospital.state) \(hospital.zipCode)")
                                    .font(.footnote)
                                    .foregroundColor(.secondary)
                                    .lineLimit(2)
                            }
                        } else {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("No hospital specified")
                                    .font(.headline)
                                Text("Select a hospital for this delivery.")
                                    .font(.footnote)
                                    .foregroundColor(.secondary)
                            }
                        }
                        Spacer()
                        Button("Edit") { showHospitalSheet = true }
                            .buttonStyle(.borderedProminent)
                            .tint(.red)
                            .foregroundColor(.white)
                            
                    }
                }

                Section("Babies") {
                    if let babies = delivery.babies, !babies.isEmpty {
                        ForEach(babies) { baby in
                            HStack {
                                Image(systemName: "figure.child")
                                    .foregroundStyle(baby.sex.color)
                                Text(baby.sex.displayName)
                                Spacer()
                                Text("\(weightDisplay(baby.weight)), \(heightDisplay(baby.height))")
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
                        .onDelete { indexSet in
                            var current = delivery.babies ?? []
                            for index in indexSet.sorted(by: >) {
                                if index >= 0 && index < current.count {
                                    let baby = current[index]
                                    // Detach and remove
                                    baby.delivery = nil
                                    current.remove(at: index)
                                }
                            }
                            delivery.babies = current
                            delivery.babyCount = current.count
                            do { try modelContext.save() } catch { print("Save failed: \(error)") }
                            Task { await deliveryManager.refresh() }
                        }
                    } else {
                        Text("No babies recorded.")
                            .foregroundStyle(.secondary)
                    }

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
            }
            .navigationTitle("Edit Delivery")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(.storkOrange)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        // Ensure inverse relationships are consistent
                        for baby in delivery.babies ?? [] { baby.delivery = delivery }
                        delivery.babyCount = delivery.babies?.count ?? 0
                        do { try modelContext.save() } catch { print("Save failed: \(error)") }
                        Task { await deliveryManager.refresh() }
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showHospitalSheet) {
                HospitalsView(selectionMode: true) { hospital in
                    delivery.hospitalId = hospital.remoteId
                }
            }
            .sheet(isPresented: $showBabySheet) {
                BabyEditSheet(
                    baby: editingBaby,
                    onSave: { updated in
                        var list = delivery.babies ?? []
                        if let existing = editingBaby, let idx = list.firstIndex(where: { $0.id == existing.id }) {
                            // mutate existing in place
                            list[idx].sex = updated.sex
                            list[idx].weight = updated.weight
                            list[idx].height = updated.height
                            list[idx].nicuStay = updated.nicuStay
                            list[idx].nurseCatch = updated.nurseCatch
                            list[idx].birthday = updated.birthday
                        } else {
                            // create new and attach
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
                        // Ensure inverse relationships
                        for b in list { b.delivery = delivery }
                        delivery.babies = list
                        delivery.babyCount = list.count
                        do { try modelContext.save() } catch { print("Save failed: \(error)") }
                        Task { await deliveryManager.refresh() }
                    },
                    onCancel: {
                        // no-op
                    }
                )
                .interactiveDismissDisabled()
            }
        }
    }

    private func weightDisplay(_ ounces: Double) -> String {
        if useMetricUnits {
            let grams = ounces * 28.349523125
            return "\(Int(round(grams))) g"
        } else {
            return String(format: "%.1f oz", ounces)
        }
    }

    private func heightDisplay(_ inches: Double) -> String {
        if useMetricUnits {
            let cm = inches * 2.54
            return String(format: "%.1f cm", cm)
        } else {
            return String(format: "%.1f in", inches)
        }
    }
}

private struct BabyEditSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    @AppStorage(AppStorageKeys.useMetricUnits) private var useMetricUnits: Bool = false

    struct Draft {
        var sex: Sex
        var weight: Double
        var height: Double
        var nicuStay: Bool
        var nurseCatch: Bool
        var birthday: Date
    }

    var baby: Baby?
    var onSave: (Draft) -> Void
    var onCancel: () -> Void

    @State private var draft: Draft

    init(baby: Baby?, onSave: @escaping (Draft) -> Void, onCancel: @escaping () -> Void) {
        self.baby = baby
        self.onSave = onSave
        self.onCancel = onCancel
        if let b = baby {
            _draft = State(initialValue: Draft(sex: b.sex, weight: b.weight, height: b.height, nicuStay: b.nicuStay, nurseCatch: b.nurseCatch, birthday: b.birthday))
        } else {
            _draft = State(initialValue: Draft(sex: .male, weight: 121.6, height: 19.0, nicuStay: false, nurseCatch: false, birthday: Date()))
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
        let schema = Schema([Delivery.self, User.self, Baby.self])
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        return try! ModelContainer(for: schema, configurations: [configuration])
    }()
    let context = ModelContext(container)
    let d = Delivery.sample()
    return DeliveryEditFormView(delivery: d)
        .environment(DeliveryManager(context: context))
        .environment(HospitalManager())
        .environment(UserManager(context: context))
}
