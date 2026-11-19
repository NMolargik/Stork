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
    /// Builds the detail for a delivery; when given, wide layouts (iPad regular width, unfolded
    /// iPhone Duo) show the list on the left and the selected delivery's detail on the right.
    private let detail: ((Delivery) -> DeliveryDetailView)?
    /// Reports whether the list is currently showing the side-by-side layout, so the embedding
    /// screen can select a delivery (deep link, Spotlight) instead of pushing over the split view.
    @Binding private var isShowingSplit: Bool

    @Environment(\.horizontalSizeClass) private var hSizeClass
    @State private var layout = LayoutProbe()
    @State private var showingFilterSheet = false
    @State private var searchText = ""

    public init(
        model: DeliveryListModel,
        showingEntrySheet: Binding<Bool>,
        isShowingSplit: Binding<Bool> = .constant(false),
        detail: ((Delivery) -> DeliveryDetailView)? = nil
    ) {
        self.model = model
        _showingEntrySheet = showingEntrySheet
        _isShowingSplit = isShowingSplit
        self.detail = detail
    }

    private var usesSplit: Bool {
        detail != nil && layout.usesTwoColumns(isRegularWidth: hSizeClass == .regular)
    }

    public var body: some View {
        Group {
            if model.deliveries.isEmpty {
                EmptyState(model: model, showingEntrySheet: $showingEntrySheet)
            } else if usesSplit, let detail {
                SplitColumns {
                    listContent(splitSelection: true)
                } trailing: {
                    DetailPane(model: model, detail: detail)
                }
            } else {
                listContent(splitSelection: false)
            }
        }
        .containerLayoutProbe { layout = $0 }
        .onChange(of: usesSplit, initial: true) { _, split in isShowingSplit = split }
        .searchable(text: $searchText, prompt: Text("Search notes, tags, and methods", bundle: .module))
        .onChange(of: searchText) { _, newValue in model.setSearchText(newValue) }
        .onAppear {
            model.load()
            #if DEBUG
            if DebugLaunchOptions.openSheet == "filter" { showingFilterSheet = true }
            #endif
        }
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

    @ViewBuilder
    private func listContent(splitSelection: Bool) -> some View {
        if model.visibleDeliveries.isEmpty {
            NoMatchesState(model: model, searchText: searchText)
        } else {
            ListBody(model: model, splitSelection: splitSelection)
        }
    }

    // MARK: - States

    /// The right-hand pane: the selected delivery's detail, or a calm placeholder when the
    /// filters leave nothing to show.
    private struct DetailPane: View {
        var model: DeliveryListModel
        let detail: (Delivery) -> DeliveryDetailView

        var body: some View {
            if let delivery = model.selectedDelivery {
                detail(delivery)
                    .id(delivery.id)
            } else {
                ContentUnavailableView {
                    Label(String(localized: "No Delivery Selected", bundle: .module), systemImage: "rectangle.on.rectangle.slash")
                } description: {
                    Text("Choose a delivery from the list to see its details here.", bundle: .module)
                }
            }
        }
    }

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
        /// Side-by-side layout: rows select into the detail pane instead of pushing.
        var splitSelection = false

        var body: some View {
            let source = DeliveryStatistics.logged(model.visibleDeliveries)
            let estimated = model.visibleDeliveries.filter(\.isEstimated).sorted { $0.date > $1.date }
            let months = model.monthStarts(from: source)

            List {
                ForEach(months, id: \.self) { monthStart in
                    let monthDeliveries = model.deliveries(in: monthStart, from: source)
                    if !monthDeliveries.isEmpty {
                        Section(header: Text(WeekMath.monthHeaderTitle(for: monthStart)).font(.title2.bold())) {
                            ForEach(monthDeliveries) { delivery in
                                row(for: delivery)
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

                if !estimated.isEmpty {
                    Section(header: Text("Earlier Career (Estimated)", bundle: .module).font(.title2.bold())) {
                        ForEach(estimated) { delivery in
                            EstimatedBirthsRow(delivery: delivery)
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        Haptics.error()
                                        model.delete(delivery)
                                    } label: {
                                        Label(String(localized: "Delete", bundle: .module), systemImage: "trash")
                                    }
                                }
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                                .listRowInsets(EdgeInsets(top: 4, leading: 20, bottom: 4, trailing: 20))
                        }
                    }
                }
            }
            .listStyle(.plain)
            .frame(maxWidth: splitSelection ? .infinity : 760)
            .frame(maxWidth: .infinity)
            .refreshable { await model.refresh() }
        }

        @ViewBuilder
        private func row(for delivery: Delivery) -> some View {
            if splitSelection {
                let isSelected = model.selectedDelivery?.id == delivery.id
                Button {
                    Haptics.lightImpact()
                    model.selectedDeliveryID = delivery.id
                } label: {
                    DeliveryRowView(delivery: delivery)
                        .overlay {
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .strokeBorder(Color.primary.opacity(isSelected ? 0.85 : 0), lineWidth: 3)
                        }
                        .contentShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .hoverEffect(.lift)
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            } else {
                NavigationLink(value: delivery) {
                    DeliveryRowView(delivery: delivery)
                        .contentShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .hoverEffect(.lift)
                }
                .navigationLinkIndicatorVisibility(.hidden)
                .buttonStyle(.plain)
            }
        }
    }
}
#endif
