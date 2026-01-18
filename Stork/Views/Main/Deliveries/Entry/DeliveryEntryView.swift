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
    
    init(existingDelivery: Delivery? = nil, onDeliverySaved: @escaping (Delivery, UIWindowScene?) -> Void) {
        self.existingDelivery = existingDelivery
        self.onDeliverySaved = onDeliverySaved
        self._viewModel = State(initialValue: ViewModel(existingDelivery: existingDelivery))
    }

    // MARK: - Actions

    private func removeTag(at index: Int) {
        viewModel.selectedTags.remove(at: index)
    }

    private func removeBaby(at index: Int) {
        viewModel.babies.remove(at: index)
    }

    private func saveDelivery() {
        if let existing = existingDelivery {
            let temp = Delivery(
                id: existing.id,
                date: viewModel.date,
                babies: viewModel.babies,
                babyCount: viewModel.babies.count,
                deliveryMethod: viewModel.deliveryMethod,
                epiduralUsed: viewModel.epiduralUsed,
                notes: viewModel.notes.isEmpty ? nil : viewModel.notes,
                tags: viewModel.selectedTags
            )
            onDeliverySaved(temp, nil)
            dismiss()
        } else {
            let newDelivery = Delivery(
                date: viewModel.date,
                babies: viewModel.babies,
                babyCount: viewModel.babies.count,
                deliveryMethod: viewModel.deliveryMethod,
                epiduralUsed: viewModel.epiduralUsed,
                notes: viewModel.notes.isEmpty ? nil : viewModel.notes,
                tags: viewModel.selectedTags
            )
            onDeliverySaved(newDelivery, nil)
            dismiss()
        }
    }

    // MARK: - View Sections

    @ViewBuilder
    private var detailsSection: some View {
        Section("Details") {
            DatePicker("Date", selection: $viewModel.date, in: viewModel.dateRange, displayedComponents: [.date, .hourAndMinute])
                .datePickerStyle(.compact)
                .disabled(existingDelivery != nil)
                .foregroundColor(existingDelivery != nil ? .gray : .primary)
                .onChange(of: viewModel.date) { _, _ in
                    viewModel.clampDate()
                }
                .accessibilityLabel("Delivery date and time")
                .accessibilityHint(existingDelivery != nil ? "Date cannot be changed when editing" : "Select the date and time of delivery")

            if !viewModel.dateRange.contains(viewModel.date) {
                Text("Date and time must be between \(viewModel.dateRange.lowerBound.formattedMediumDateTime()) and \(viewModel.dateRange.upperBound.formattedMediumDateTime()).")
                    .foregroundColor(.red)
                    .font(.footnote)
                    .accessibilityLabel("Error: Date must be within the last 3 days")
            }

            Picker("Delivery Method", selection: $viewModel.deliveryMethod) {
                ForEach(DeliveryMethod.allCases, id: \.self) { method in
                    Text(method.description).tag(method)
                }
            }
            .pickerStyle(.segmented)
            .accessibilityLabel("Delivery method")
            .accessibilityHint("Select vaginal, C-section, or V-BAC")

            Toggle("Epidural Used", isOn: $viewModel.epiduralUsed)
                .tint(.red)
                .accessibilityLabel("Epidural used")
                .accessibilityHint("Toggle whether an epidural was administered")
        }
    }

    @ViewBuilder
    private var babiesSection: some View {
        Section {
            babiesSectionContent
        } header: {
            Text("Babies")
        }
    }

    @ViewBuilder
    private var babiesSectionContent: some View {
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
                .hoverEffect(.highlight)
                .accessibilityLabel("Add baby")
                .accessibilityHint("Opens form to add a new baby to this delivery")
            }

            babiesList

            if viewModel.babies.isEmpty {
                Text("At least one baby is required to finish.")
                    .font(.footnote)
                    .foregroundColor(.red)
            }
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private var babiesList: some View {
        if viewModel.babies.isEmpty {
            Text("No babies added yet.")
                .foregroundColor(.secondary)
                .padding(.vertical, 8)
        } else {
            ForEach(viewModel.babies) { baby in
                babyRow(baby)
            }
        }
    }

    @ViewBuilder
    private func babyRow(_ baby: Baby) -> some View {
        BabyRowView(
            baby: baby,
            useMetricUnits: useMetricUnits,
            onEdit: {
                editingBaby = baby
                viewModel.showingBabySheet = true
            },
            onDelete: {
                if let index = viewModel.babies.firstIndex(where: { $0.id == baby.id }) {
                    removeBaby(at: index)
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

    @ViewBuilder
    private var tagsSection: some View {
        Section {
            tagsSectionContent
        } header: {
            Text("Tags")
        } footer: {
            Text("Examples: \"Teaching Moment\", \"First Solo\", \"Night Shift\"")
        }
    }

    @ViewBuilder
    private var tagsSectionContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Tags")
                    .font(.headline)
                Spacer()
                Button {
                    viewModel.showingTagSheet = true
                } label: {
                    Label("Add", systemImage: "plus")
                        .labelStyle(.titleOnly)
                }
                .buttonStyle(.bordered)
                .tint(.storkPurple)
                .hoverEffect(.highlight)
                .accessibilityLabel("Add tags")
                .accessibilityHint("Opens picker to add tags to this delivery")
            }

            if viewModel.selectedTags.isEmpty {
                Text("No tags added. Tags help you find memorable deliveries later.")
                    .foregroundColor(.secondary)
                    .font(.footnote)
            } else {
                FlowLayout(spacing: 8) {
                    ForEach(viewModel.selectedTags) { tag in
                        TagChipView(tag: tag) {
                            if let index = viewModel.selectedTags.firstIndex(where: { $0.id == tag.id }) {
                                removeTag(at: index)
                            }
                        }
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private var notesSection: some View {
        Section {
            TextField("Add a personal note...", text: $viewModel.notes, axis: .vertical)
                .lineLimit(3...6)
                .accessibilityLabel("Delivery notes")
                .accessibilityHint("Add personal memories about this delivery")
        } header: {
            Text("Notes")
        } footer: {
            Text("Private notes for memorable deliveries. No PHI - just personal memories like \"twins on Christmas!\"")
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                detailsSection
                babiesSection
                tagsSection
                notesSection
            }
            .navigationTitle(existingDelivery == nil ? "New Delivery" : "Edit Delivery")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(.storkOrange)
                        .accessibilityLabel("Cancel")
                        .accessibilityHint("Discards changes and closes the form")
                        .keyboardShortcut(.escape, modifiers: [])
                        .hoverEffect(.highlight)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(existingDelivery == nil ? "Finish" : "Save", action: saveDelivery)
                        .disabled(!viewModel.canFinish)
                        .accessibilityLabel(existingDelivery == nil ? "Finish delivery" : "Save changes")
                        .accessibilityHint(viewModel.canFinish ? "Saves the delivery record" : "Add at least one baby to enable")
                        .keyboardShortcut(.return, modifiers: .command)
                        .hoverEffect(.highlight)
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
            .sheet(isPresented: $viewModel.showingTagSheet) {
                TagPickerSheet(selectedTags: $viewModel.selectedTags)
                    .presentationDetents([.medium, .large])
            }
        }
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
    }
}

