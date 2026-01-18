import SwiftUI
import SwiftData

struct DeliveryListView: View {
    @Environment(DeliveryManager.self) private var deliveryManager: DeliveryManager
    @Binding var showingEntrySheet: Bool
    
    @State private var showingFilterSheet: Bool = false
    @State private var filter: DeliveryFilter = DeliveryFilter()
    @State private var viewModel = ViewModel()
    
    var body: some View {
        Group {
            if deliveryManager.visibleDeliveries.isEmpty && deliveryManager.deliveries.isEmpty {
                ScrollView {
                    ContentUnavailableView(
                        "No Deliveries Yet",
                        systemImage: "list.bullet.rectangle",
                        description: Text("Your logged deliveries will appear here.")
                    )
                    .accessibilityLabel("No deliveries yet. Your logged deliveries will appear here.")
                }
                .refreshable {
                    await deliveryManager.refresh()
                }
            } else {
                let source = viewModel.source(from: deliveryManager)
                let months = viewModel.monthStarts(from: source)
                
                List {
                    ForEach(months, id: \.self) { monthStart in
                        let monthDeliveries = viewModel.deliveries(in: monthStart, from: source)
                        
                        if !monthDeliveries.isEmpty {
                            Section(header: Text(deliveryManager.headerTitle(for: monthStart)).bold().font(.title)) {
                                ForEach(monthDeliveries) { delivery in
                                    NavigationLink(value: delivery) {
                                        DeliveryRowView(delivery: delivery)
                                            .contentShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                                            .hoverEffect(.lift)
                                    }
                                    .navigationLinkIndicatorVisibility(.hidden) // Add this to hide the chevron
                                    .buttonStyle(.plain)
                                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                        Button(role: .destructive) {
                                            Haptics.error()
                                            Task { deliveryManager.delete(delivery) }
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                                .tint(.red)
                                        }
                                        .accessibilityLabel("Delete delivery")
                                        .accessibilityHint("Permanently removes this delivery")
                                    }
                                    .listRowBackground(Color.clear)
                                    .listRowSeparator(.hidden)
                                    .listRowInsets(EdgeInsets(top: 4, leading: 20, bottom: 4, trailing: 20))
                                }
                            }
                        }
                    }
                }
                .listStyle(.plain) // Ensure consistent list behavior
                .refreshable {
                    await deliveryManager.refresh()
                }
            }
        }
        .navigationDestination(for: Delivery.self) { delivery in
            DeliveryDetailView(delivery: delivery)
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(action: {
                    showingFilterSheet = true
                }) {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                }
                .tint(.green)
                .accessibilityLabel("Filter deliveries")
                .accessibilityHint("Opens filter options for the delivery list")
                .keyboardShortcut("f", modifiers: .command)
                .hoverEffect(.highlight)
            }
        }
        .sheet(isPresented: $showingFilterSheet) {
            DeliveryFilterSheet(filter: $filter)
                .onDisappear {
                    deliveryManager.applyFilter(filter)
                }
        }
    }
}

#Preview("Delivery List") {
    let container: ModelContainer = {
        let schema = Schema([Delivery.self, User.self, Baby.self])
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        return try! ModelContainer(for: schema, configurations: [configuration])
    }()
    let context = ModelContext(container)
    
    NavigationStack {
        DeliveryListView(showingEntrySheet: .constant(false))
            .environment(DeliveryManager(context: context))
    }
}
