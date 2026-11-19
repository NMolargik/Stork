//
//  DashboardView.swift
//  StorkFeatureDashboard
//
//  The dashboard: the marble jar pinned at the top, then reorderable statistic cards that
//  flow into two balanced columns at regular width.
//

#if os(iOS)
import SwiftUI
import StorkCore
import StorkDesignSystem

public struct DashboardView: View {
    @Bindable private var model: DashboardModel
    @Binding private var showingReorderSheet: Bool
    @Environment(\.horizontalSizeClass) private var hSizeClass
    @State private var jarShuffle = false
    @State private var layout = LayoutProbe()
    @Environment(\.bottomAccessoryClearance) private var accessoryClearance
    @State private var legendHeight: CGFloat = 130
    @AppStorage(AppStorageKeys.excludedBirthRoles) private var excludedRoles = ""

    public init(model: DashboardModel, showingReorderSheet: Binding<Bool>) {
        self.model = model
        _showingReorderSheet = showingReorderSheet
    }

    /// Space under the last card so it can scroll fully above the floating step pill (a bottom
    /// accessory the system does not inset iPad content for).
    private static let pillClearance: CGFloat = 84

    private var usesTwoColumns: Bool { layout.usesTwoColumns(isRegularWidth: hSizeClass == .regular) }

    public var body: some View {
        Group {
            if usesTwoColumns { wideBody } else { stackedBody }
        }
        .containerLayoutProbe { layout = $0 }
        .refreshable {
            jarShuffle = true
            await model.refresh()
        }
        .onAppear {
            model.load()
            #if DEBUG
            if let year = DebugLaunchOptions.openWrapYear, model.presentedWrapYear == nil { model.presentedWrapYear = year }
            #endif
        }
        .sheet(item: wrapSelection) { selection in
            YearWrapView(model: model.makeWrapModel(year: selection.year, counting: BirthRoleCounting(storedValue: excludedRoles)))
                .presentationDetents([.large])
                .presentationSizing(.page)
        }
        .sheet(isPresented: $showingReorderSheet) {
            DashboardCardOrderSheet(currentOrder: model.cardOrder) { model.saveOrder($0) }
                .presentationDetents([.large])
        }
    }

    private var stackedBody: some View {
        // Content scrolls under the floating step pill (as on iPhone); on the Duo a bottom content
        // margin lets the last card scroll fully clear of it.
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 20) {
                    wrapPrompt
                    JarSection(model: model, jarShuffle: $jarShuffle)

                    ForEach(model.cardOrder) { card(for: $0) }
                }
                .frame(maxWidth: 1000)
                .frame(maxWidth: .infinity)
                .padding(.horizontal)
                .padding(.bottom, PhoneDuo.isDuo && accessoryClearance > 0 ? 16 : Self.pillClearance)
            }
            .contentMargins(.bottom, PhoneDuo.isDuo ? accessoryClearance : 0, for: .scrollContent)
            #if DEBUG
            .task {
                // Simulator verification: `-StorkScrollToCard N` (the folded Duo does not scroll from simulated touches).
                guard let index = DebugLaunchOptions.scrollToCard else { return }
                try? await Task.sleep(for: .seconds(2))
                let order = model.cardOrder
                if order.indices.contains(index) { proxy.scrollTo(order[index].id, anchor: .top) }
            }
            #endif
        }
    }

    /// The unfolded iPhone Duo and iPad in regular width: the jar with its legend on the left,
    /// the statistic cards on the right, each column scrolling on its own.
    private var wideBody: some View {
        SplitColumns {
            GeometryReader { proxy in
                // The jar, legend and Share Jar fit the column's visible height (above the step
                // pill) without scrolling, top-aligned. The jar takes what the legend leaves, up
                // to a squarish panel; a very large type size falls back to scrolling.
                let available = proxy.size.height - accessoryClearance - 16
                let width = max(proxy.size.width - 32, 200)
                let jarHeight = min(max(available - legendHeight - 12, 220), width * 1.1)
                ScrollView {
                    JarSection(model: model, jarShuffle: $jarShuffle, jarHeight: jarHeight, marbleScale: 1.3) { legendHeight = $0 }
                        .padding(.horizontal)
                        .padding(.top, 8)
                        .padding(.bottom, accessoryClearance + 16)
                }
                .scrollBounceBehavior(.basedOnSize)
            }
        } trailing: {
            ScrollView {
                VStack(spacing: 16) {
                    wrapPrompt
                    ForEach(model.cardOrder) { card(for: $0) }
                }
                .padding(.horizontal)
                .padding(.bottom, accessoryClearance + 16)
            }
        }
        .frame(maxWidth: layout.hasFold ? .infinity : 1400)
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private var wrapPrompt: some View {
        if let wrapYear = model.wrapPromptYear(counting: BirthRoleCounting(storedValue: excludedRoles)) {
            YearWrapPromptCard(
                year: wrapYear,
                onOpen: { model.presentedWrapYear = wrapYear },
                onDismiss: { withAnimation { model.dismissWrapPrompt(year: wrapYear) } }
            )
            .transition(.opacity)
        }
    }

    private var wrapSelection: Binding<WrapSelection?> {
        Binding(get: { model.presentedWrapYear.map(WrapSelection.init) }, set: { model.presentedWrapYear = $0?.year })
    }

    @ContentBuilder
    private func card(for card: DashboardCard) -> some View {
        if model.isLocked(card) {
            LockedInsightCard(card: card)
        } else {
            CardView(card: card, deliveries: model.deliveries)
        }
    }

    /// Teaser for a Pro insight card: same chrome and title, lock in place of the chart.
    private struct LockedInsightCard: View {
        let card: DashboardCard
        @Environment(\.requestProUpgrade) private var requestProUpgrade

        var body: some View {
            Button {
                Haptics.lightImpact()
                requestProUpgrade(.insightCards)
            } label: {
                InsightCard(title: card.displayName, systemImage: card.systemImage, accent: .storkPurple) {
                    HStack(spacing: 12) {
                        Image(systemName: "lock.fill").font(.title3).foregroundStyle(.secondary).accessibilityHidden(true)
                        Text("Unlock insight cards with Stork Pro", bundle: .module)
                            .font(.subheadline).foregroundStyle(.secondary)
                            .multilineTextAlignment(.leading)
                        Spacer()
                        ProBadge()
                    }
                    .frame(minHeight: 50)
                }
            }
            .buttonStyle(.plain)
            .accessibilityHint(Text("Opens Stork Pro", bundle: .module))
        }
    }

    private struct JarSection: View {
        var model: DashboardModel
        @Binding var jarShuffle: Bool
        /// Fixed height for the jar; nil keeps the compact default.
        var jarHeight: CGFloat?
        var marbleScale: CGFloat = 1
        /// Reports the height of everything under the jar (legend, notes, Share Jar).
        var onBelowJarHeight: ((CGFloat) -> Void)?
        @State private var selection: JarCategory?

        private var jarDebugBoost: CGFloat {
            #if DEBUG
            DebugLaunchOptions.jarMarbleScale ?? 1
            #else
            1
            #endif
        }

        var body: some View {
            let marbles = model.jarMarbles
            VStack(spacing: 12) {
                JarView(
                    marbles: marbles,
                    highlight: selection,
                    history: AnyView(JarHistoryView(deliveries: model.loggedDeliveries, isProUnlocked: model.isProUnlocked)),
                    marbleScale: marbleScale * jarDebugBoost,
                    reshuffle: $jarShuffle
                )
                .id(WeekMath.startOfMonth(for: model.jarDate))
                .frame(height: jarHeight ?? 250)

                VStack(spacing: 12) {
                    JarLegendView(marbles: marbles, monthDate: model.jarDate, isProUnlocked: model.isProUnlocked, selection: $selection)
                    estimateNote
                }
                .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { onBelowJarHeight?($0) }
            }
        }

        @ViewBuilder
        private var estimateNote: some View {
            if model.estimatedBabyCount > 0 {
                Label {
                    Text("Plus ^[\(model.estimatedBabyCount) earlier baby](inflect: true), estimated. These are in your career totals, not this month's jar.", bundle: .module)
                } icon: {
                    Image(systemName: "sparkles").accessibilityHidden(true)
                }
                .font(.caption).foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private struct CardView: View {
        let card: DashboardCard
        let deliveries: [Delivery]

        var body: some View {
            switch card {
            case .deliveryMethod: DeliveryMethodCard(deliveries: deliveries)
            case .epiduralNicu:
                HStack(spacing: 12) {
                    EpiduralUsageCard(deliveries: deliveries).frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    NICUStayCard(deliveries: deliveries).frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                }
                .fixedSize(horizontal: false, vertical: true)
            case .babyCount: BabyCountCard(deliveries: deliveries)
            case .babyMeasurements: BabyMeasurementsCard(deliveries: deliveries)
            case .sexDistribution: SexDistributionCard(deliveries: deliveries)
            case .timeOfDay: TimeOfDayCard(deliveries: deliveries)
            case .dayOfWeek: DayOfWeekCard(deliveries: deliveries)
            case .yearOverYear: YearOverYearCard(deliveries: deliveries)
            case .personalBests: PersonalBestsCard(deliveries: deliveries)
            case .roleBreakdown: RoleBreakdownCard(deliveries: deliveries)
            }
        }
    }
}
#endif
