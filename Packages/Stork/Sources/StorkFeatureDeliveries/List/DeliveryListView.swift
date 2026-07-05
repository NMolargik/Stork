//
//  DeliveryListView.swift
//  StorkFeatureDeliveries
//
//  The month-grouped delivery list. Search and the filter sheet feed the same
//  `DeliveryFilter` through `DeliveryListModel`; an active filter that matches nothing
//  shows the "No Matches" / search empty state rather than the unfiltered list.
//
//  Navigation destinations and the entry sheet are owned by the embedding screen, so
//  rows emit `NavigationLink(value:)` and the toolbar add button toggles a binding.
//

#if os(iOS)
import SwiftUI
import StorkCore
import StorkDesignSystem

public struct DeliveryListView: View {
    @Bindable private var model: DeliveryListModel
    @Binding private var showingEntrySheet: Bool

    @State private var showingFilterSheet = false
    @State private var searchText = ""

    public init(model: DeliveryListModel, showingEntrySheet: Binding<Bool>) {
        self.model = model
        _showingEntrySheet = showingEntrySheet
    }

    public var body: some View {
        Group {
            if model.deliveries.isEmpty {
                EmptyState(model: model, showingEntrySheet: $showingEntrySheet)
            } else if model.visibleDeliveries.isEmpty {
                NoMatchesState(model: model, searchText: searchText)
            } else {
                ListBody(model: model)
            }
        }
        .searchable(text: $searchText, prompt: Text("Search notes, tags, and methods", bundle: .module))
        .onChange(of: searchText) { _, newValue in model.setSearchText(newValue) }
        .onAppear { model.load() }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    showingFilterSheet = true
                } label: {
                    Image(systemName: model.hasActiveFilters
                          ? "line.3.horizontal.decrease.circle.fill"
                          : "line.3.horizontal.decrease.circle")
                        .contentTransition(.symbolEffect(.replace))
                }
                .accessibilityLabel(Text("Filter deliveries", bundle: .module))
                .accessibilityHint(Text("Opens filter options for the delivery list", bundle: .module))
                .keyboardShortcut("f", modifiers: .command)
                .hoverEffect(.highlight)
            }
        }
        .sheet(isPresented: $showingFilterSheet) {
            DeliveryFilterSheet(filter: $model.filter, availableTags: model.availableTags)
        }
    }

    // MARK: - States

    private struct EmptyState: View {
        var model: DeliveryListModel
        @Binding var showingEntrySheet: Bool

        var body: some View {
            ScrollView {
                ContentUnavailableView {
                    Label(String(localized: "No Deliveries Yet", bundle: .module), systemImage: "list.bullet.rectangle")
                } description: {
                    Text("Your logged deliveries will appear here.", bundle: .module)
                } actions: {
                    Button {
                        showingEntrySheet = true
                    } label: {
                        Label(String(localized: "Log a Delivery", bundle: .module), systemImage: "plus")
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .refreshable { await model.refresh() }
        }
    }

    private struct NoMatchesState: View {
        var model: DeliveryListModel
        let searchText: String

        var body: some View {
            if searchText.isEmpty {
                ContentUnavailableView {
                    Label(String(localized: "No Matches", bundle: .module), systemImage: "line.3.horizontal.decrease.circle")
                } description: {
                    Text("No deliveries match the current filters.", bundle: .module)
                } actions: {
                    Button(String(localized: "Clear Filters", bundle: .module)) { model.clearFilters(keepingSearch: searchText) }
                }
            } else {
                ContentUnavailableView.search(text: searchText)
            }
        }
    }

    private struct ListBody: View {
        var model: DeliveryListModel

        var body: some View {
            let source = model.visibleDeliveries
            let months = model.monthStarts(from: source)

            List {
                ForEach(months, id: \.self) { monthStart in
                    let monthDeliveries = model.deliveries(in: monthStart, from: source)
                    if !monthDeliveries.isEmpty {
                        Section(header: Text(WeekMath.monthHeaderTitle(for: monthStart)).font(.title2.bold())) {
                            ForEach(monthDeliveries) { delivery in
                                NavigationLink(value: delivery) {
                                    DeliveryRowView(delivery: delivery)
                                        .contentShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                                        .hoverEffect(.lift)
                                }
                                .navigationLinkIndicatorVisibility(.hidden)
                                .buttonStyle(.plain)
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        Haptics.error()
                                        model.delete(delivery)
                                    } label: {
                                        Label(String(localized: "Delete", bundle: .module), systemImage: "trash")
                                    }
                                    .accessibilityLabel(Text("Delete delivery", bundle: .module))
                                    .accessibilityHint(Text("Permanently removes this delivery", bundle: .module))
                                }
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                                .listRowInsets(EdgeInsets(top: 4, leading: 20, bottom: 4, trailing: 20))
                            }
                        }
                    }
                }
            }
            .listStyle(.plain)
            .frame(maxWidth: 760)
            .frame(maxWidth: .infinity)
            .refreshable { await model.refresh() }
        }
    }
}
#endif
