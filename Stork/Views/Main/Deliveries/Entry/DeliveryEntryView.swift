import SwiftUI
import SwiftData

struct DeliveryEntryView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage(AppStorageKeys.useMetricUnits) private var useMetricUnits: Bool = false
    var existingDelivery: Delivery? // Optional for edit mode
    var onDeliverySaved: (Delivery, UIWindowScene?) -> Void
    @State private var viewModel: ViewModel
    
    @State private var editingBaby: Baby?
    
    @Environment(UserManager.self) private var userManager: UserManager
    @Environment(HospitalManager.self) private var hospitalManager: HospitalManager

    @State private var showHospitalSheet: Bool = false
    @State private var selectedHospitalId: String? = nil
    
    init(existingDelivery: Delivery? = nil, onDeliverySaved: @escaping (Delivery, UIWindowScene?) -> Void) {
        self.existingDelivery = existingDelivery
        self.onDeliverySaved = onDeliverySaved
        self._viewModel = State(initialValue: ViewModel(existingDelivery: existingDelivery))
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    DatePicker("Date", selection: $viewModel.date, in: viewModel.dateRange, displayedComponents: [.date, .hourAndMinute])
                        .datePickerStyle(.compact)
                        .disabled(existingDelivery != nil) // Disable in edit mode
                        .foregroundColor(existingDelivery != nil ? .gray : .primary)
                        .onChange(of: viewModel.date) { _, _ in
                            viewModel.clampDate()
                        }
                    
                    if !viewModel.dateRange.contains(viewModel.date) {
                        Text("Date and time must be between \(formattedDate(viewModel.dateRange.lowerBound)) and \(formattedDate(viewModel.dateRange.upperBound)).")
                            .foregroundColor(.red)
                            .font(.footnote)
                    }
                    
                    Picker("Delivery Method", selection: $viewModel.deliveryMethod) {
                        ForEach(DeliveryMethod.allCases, id: \.self) { method in
                            Text(method.description).tag(method)
                        }
                    }
                    .pickerStyle(.segmented)
                    Toggle("Epidural Used", isOn: $viewModel.epiduralUsed)
                        .tint(.red)
                }
                
                Section("Hospital") {
                    HStack(alignment: .top) {
                        let effectiveHospitalId = selectedHospitalId ?? userManager.currentUser?.primaryHospitalId
                        if let hospital = hospitalById(effectiveHospitalId) {
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
                                Text("No primary hospital set!")
                                    .font(.headline)
                                Text("Select a hospital for this delivery.")
                                    .font(.footnote)
                                    .foregroundColor(.secondary)
                            }
                        }
                        Spacer()
                        Button("Edit") {
                            showHospitalSheet = true
                        }
                        .buttonStyle(.bordered)
                        .tint(.red)
                    }
                    .contentShape(Rectangle())
                }
                
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Babies")
                                .font(.headline)
                            Spacer()
                            Button {
                                editingBaby = nil
                                viewModel.showingBabySheet = true
                            } label: {
                                Label("Add", systemImage: "plus")
                                    .labelStyle(.titleOnly)
                            }
                            .buttonStyle(.bordered)
                            .tint(.storkBlue)
                        }
                        
                        if viewModel.babies.isEmpty {
                            Text("No babies added yet.")
                                .foregroundColor(.secondary)
                                .padding(.vertical, 8)
                        } else {
                            ForEach(viewModel.babies) { baby in
                                BabyRowView(
                                    baby: baby,
                                    useMetricUnits: useMetricUnits,
                                    onEdit: {
                                        editingBaby = baby
                                        viewModel.showingBabySheet = true
                                    },
                                    onDelete: {
                                        if let index = viewModel.babies.firstIndex(where: { $0.id == baby.id }) {
                                            viewModel.babies.remove(at: index)
                                        }
                                    }
                                )
                                .padding(.vertical, 4)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color(.systemBackground))
                                        .shadow(radius: 2)
                                )
                            }
                        }
                        
                        Text("At least one baby is required to finish.")
                            .font(.footnote)
                            .foregroundColor(.red)
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("Babies")
                }
            }
            .onAppear {
                if selectedHospitalId == nil {
                    selectedHospitalId = userManager.currentUser?.primaryHospitalId
                }
            }
            .navigationTitle(existingDelivery == nil ? "New Delivery" : "Edit Delivery")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(.storkOrange)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(existingDelivery == nil ? "Finish" : "Save") {
                        if let existing = existingDelivery {
                            // EDIT MODE: return a non-inserted temp carrying staged values; caller will mutate `existing`
                            let temp = Delivery(
                                id: existing.id, // preserve identity to avoid duplicates
                                date: viewModel.date,
                                hospitalId: selectedHospitalId ?? userManager.currentUser?.primaryHospitalId,
                                babies: viewModel.babies,
                                babyCount: viewModel.babies.count,
                                deliveryMethod: viewModel.deliveryMethod,
                                epiduralUsed: viewModel.epiduralUsed
                            )
                            onDeliverySaved(temp, nil)
                            dismiss()
                        } else {
                            // CREATE MODE: create a brand new Delivery instance for insertion by caller
                            let newDelivery = Delivery(
                                date: viewModel.date,
                                hospitalId: selectedHospitalId ?? userManager.currentUser?.primaryHospitalId,
                                babies: viewModel.babies,
                                babyCount: viewModel.babies.count,
                                deliveryMethod: viewModel.deliveryMethod,
                                epiduralUsed: viewModel.epiduralUsed
                            )
                            onDeliverySaved(newDelivery, nil)
                            dismiss()
                        }
                    }
                    .disabled(!viewModel.canFinish)
                }
            }
            .sheet(isPresented: $viewModel.showingBabySheet) {
                BabyEntrySheet(
                    viewModel: $viewModel,
                    useMetricUnits: useMetricUnits,
                    editingBaby: editingBaby
                )
                .interactiveDismissDisabled()
                .onDisappear {
                    editingBaby = nil
                }
            }
            .sheet(isPresented: $showHospitalSheet) {
                HospitalsView(selectionMode: true) { hospital in
                    // Apply the selection locally and (optionally) update the user’s primary
                    selectedHospitalId = hospital.remoteId
                }
            }
        }
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func weightHeightSummary(for baby: Baby) -> String {
        let weightString: String
        let heightString: String
        
        if useMetricUnits {
            let weightKg = baby.weight / 35.27396
            weightString = String(format: "%.1f kg", weightKg)
            let heightCm = baby.height / 0.393701
            heightString = String(format: "%.1f cm", heightCm)
        } else {
            let totalOunces = baby.weight
            let lbs = Int(totalOunces / 16)
            let oz = Int(totalOunces.truncatingRemainder(dividingBy: 16))
            weightString = "\(lbs) lb \(oz) oz"
            
            let totalInches = baby.height
            let ft = Int(totalInches / 12)
            let inch = Int(totalInches.truncatingRemainder(dividingBy: 12))
            heightString = ft > 0 ? "\(ft) ft \(inch) in" : "\(inch) in"
        }
        
        return "\(weightString), \(heightString)"
    }
    
    private func hospitalById(_ id: String?) -> Hospital? {
        guard let id, !id.isEmpty else { return nil }
        return hospitalManager.hospitals.first { $0.remoteId == id }
    }
}

#Preview("New Delivery") {
    let container: ModelContainer = {
        let schema = Schema([Delivery.self, User.self, Baby.self])
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        return try! ModelContainer(for: schema, configurations: [configuration])
    }()
    let context = ModelContext(container)
    
    NavigationStack {
        DeliveryEntryView(onDeliverySaved: { _, _ in })
            .environment(UserManager(context: context))
            .environment(HospitalManager())
    }
}

#Preview("Edit Delivery") {
    let container: ModelContainer = {
        let schema = Schema([Delivery.self, User.self, Baby.self])
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        return try! ModelContainer(for: schema, configurations: [configuration])
    }()
    let context = ModelContext(container)
    
    NavigationStack {
        DeliveryEntryView(existingDelivery: Delivery.sample(), onDeliverySaved: { _, _ in })
            .environment(UserManager(context: context))
            .environment(HospitalManager())
    }
}

