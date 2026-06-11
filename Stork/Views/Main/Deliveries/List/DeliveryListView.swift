import SwiftUI
import AppIntents
import SwiftData

struct DeliveryListView: View {
    @Environment(DeliveryManager.self) private var deliveryManager: DeliveryManager
    @Binding var showingEntrySheet: Bool
    
    @State private var showingFilterSheet: Bool = false
    @State private var filter: DeliveryFilter = DeliveryFilter()
    @State private var searchText: String = ""
    @State private var viewModel = ViewModel()

    var body: some View {
        Group {
            if deliveryManager.deliveries.isEmpty {
                ScrollView {
                    ContentUnavailableView {
                        Label("No Deliveries Yet", systemImage: "list.bullet.rectangle")
                    } description: {
                        Text("Your logged deliveries will appear here.")
                    } actions: {
                        Button {
                            showingEntrySheet = true
                        } label: {
                            Label("Log a Delivery", systemImage: "plus")
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
                .refreshable {
                    await deliveryManager.refresh()
                }
            } else if deliveryManager.visibleDeliveries.isEmpty {
                // A filter or search is active and nothing matches — never
                // fall back to showing everything.
                if searchText.isEmpty {
                    ContentUnavailableView {
                        Label("No Matches", systemImage: "line.3.horizontal.decrease.circle")
                    } description: {
                        Text("No deliveries match the current filters.")
                    } actions: {
                        Button("Clear Filters") {
                            clearFilters()
                        }
                    }
                } else {
                    ContentUnavailableView.search(text: searchText)
                }
            } else {
                let source = deliveryManager.visibleDeliveries
                let months = viewModel.monthStarts(from: source)

                List {
                    ForEach(months, id: \.self) { monthStart in
                        let monthDeliveries = viewModel.deliveries(in: monthStart, from: source)

                        if !monthDeliveries.isEmpty {
                            Section(header: Text(WeekMath.monthHeaderTitle(for: monthStart)).font(.title2.bold())) {
                                ForEach(monthDeliveries) { delivery in
                                    NavigationLink(value: delivery) {
                                        DeliveryRowView(delivery: delivery)
                                            .contentShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                                            .hoverEffect(.lift)
                                    }
                                    // Onscreen awareness: lets the new Siri
                                    // resolve "this/that delivery" in the list.
                                    .appEntityIdentifier(EntityIdentifier(for: DeliveryEntity.self, identifier: delivery.id))
                                    .navigationLinkIndicatorVisibility(.hidden) // Add this to hide the chevron
                                    .buttonStyle(.plain)
                                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                        Button(role: .destructive) {
                                            Haptics.error()
                                            Task { deliveryManager.delete(delivery) }
                                        } label: {
                                            Label("Delete", systemImage: "trash")
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
                .frame(maxWidth: 760)
                .frame(maxWidth: .infinity)
                .refreshable {
                    await deliveryManager.refresh()
                }
            }
        }
        .searchable(text: $searchText, prompt: Text("Search notes, tags, and methods"))
        .onChange(of: searchText) { _, newValue in
            filter.searchText = newValue
            deliveryManager.applyFilter(filter)
        }
        .navigationDestination(for: Delivery.self) { delivery in
            DeliveryDetailView(delivery: delivery)
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(action: {
                    showingFilterSheet = true
                }) {
                    Image(systemName: hasActiveFilters
                          ? "line.3.horizontal.decrease.circle.fill"
                          : "line.3.horizontal.decrease.circle")
                        .contentTransition(.symbolEffect(.replace))
                }
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

    /// Whether any criteria beyond the search field are active.
    private var hasActiveFilters: Bool {
        var withoutSearch = filter
        withoutSearch.searchText = ""
        return !withoutSearch.isEmpty
    }

    private func clearFilters() {
        filter = DeliveryFilter()
        filter.searchText = searchText
        deliveryManager.applyFilter(filter)
    }
}

#Preview("Delivery List") {
    let container: ModelContainer = {
        let schema = Schema([Delivery.self, Baby.self])
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        return try! ModelContainer(for: schema, configurations: [configuration])
    }()
    
    NavigationStack {
        DeliveryListView(showingEntrySheet: .constant(false))
            .environment(DeliveryManager(container: container))
    }
}
