import SwiftUI
import SwiftData

struct DeliveryDetailView: View {
    @Environment(DeliveryManager.self) private var deliveryManager: DeliveryManager
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var hSizeClass
    
    var delivery: Delivery
    var onClose: (() -> Void)?
    @State private var showDeleteConfirm = false
    @State private var showDeleteError = false
    @State private var deleteErrorMessage: String?
    @State private var showEditSheet = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                DeliveryDetailHeaderView(delivery: delivery)
                    .padding(.horizontal)
                
                HStack {
                    Text("Babies")
                    Spacer()
                }
                .padding(.leading)
                .bold()
                
                DeliveryDetailBabyListView(babies: delivery.babies ?? [])
            }
            .padding(.bottom)
        }
        .navigationTitle("Delivery")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if hSizeClass == .regular {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        if let onClose {
                            onClose()
                        } else {
                            dismiss()
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                            Text("Close")
                        }
                    }
                }
            }
            
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showEditSheet = true
                } label: {
                    Label("Modify Delivery", systemImage: "switch.2")
                }
                .tint(.storkOrange)
                .accessibilityIdentifier("modifyDeliveryButton")
            }
            
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showDeleteConfirm = true
                } label: {
                    Label("Delete Delivery", systemImage: "trash")
                }
                .tint(.red)
                .accessibilityIdentifier("deleteDeliveryButton")
            }
        }
        .alert("Delete this delivery?", isPresented: $showDeleteConfirm) {
            Button("Delete", role: .destructive) {
                if let onClose {
                    onClose()
                } else {
                    dismiss()
                }
                deliveryManager.delete(delivery)
            }
            
            Button("Cancel", role: .cancel) { }
                .foregroundStyle(.storkOrange)
        } message: {
            Text("This action cannot be undone.")
        }
        .alert("Couldn't delete delivery", isPresented: $showDeleteError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(deleteErrorMessage ?? "An unknown error occurred. Please try again.")
        }
        .background(Color(uiColor: .systemBackground))
        .sheet(isPresented: $showEditSheet) {
            DeliveryEditFormView(delivery: delivery)
        }
    }
}

#Preview("Delivery Detail") {
    let container: ModelContainer = {
        let schema = Schema([Delivery.self, User.self, Baby.self])
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        return try! ModelContainer(for: schema, configurations: [configuration])
    }()
    let context = ModelContext(container)
    
    NavigationStack {
        DeliveryDetailView(delivery: Delivery.sample())
            .environment(DeliveryManager(context: context))
            .environment(HospitalManager())
    }
}
