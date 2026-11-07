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

    public init(model: DashboardModel, showingReorderSheet: Binding<Bool>) {
        self.model = model
        _showingReorderSheet = showingReorderSheet
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                JarSection(model: model, jarShuffle: $jarShuffle)

                if hSizeClass == .regular {
                    HStack(alignment: .top, spacing: 16) {
                        VStack(spacing: 16) { ForEach(columnCards(even: true)) { card(for: $0) } }
                        VStack(spacing: 16) { ForEach(columnCards(even: false)) { card(for: $0) } }
                    }
                } else {
                    ForEach(model.cardOrder) { card(for: $0) }
                }
            }
            .frame(maxWidth: 1000)
            .frame(maxWidth: .infinity)
            .padding(.horizontal)
            .padding(.bottom, 20)
        }
        .refreshable {
            jarShuffle = true
            await model.refresh()
        }
        .onAppear { model.load() }
        .sheet(isPresented: $showingReorderSheet) {
            DashboardCardOrderSheet(currentOrder: model.cardOrder) { model.saveOrder($0) }
                .presentationDetents([.large])
        }
    }

    private func columnCards(even: Bool) -> [DashboardCard] {
        model.cardOrder.enumerated().filter { ($0.offset % 2 == 0) == even }.map(\.element)
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
        @State private var selection: JarCategory?

        var body: some View {
            let marbles = model.jarMarbles
            VStack(spacing: 12) {
                JarView(
                    marbles: marbles,
                    highlight: selection,
                    history: AnyView(JarHistoryView(deliveries: model.deliveries, isProUnlocked: model.isProUnlocked)),
                    reshuffle: $jarShuffle
                )
                .id(WeekMath.startOfMonth(for: Date()))
                .frame(height: 250)

                JarLegendView(marbles: marbles, monthDate: Date(), isProUnlocked: model.isProUnlocked, selection: $selection)
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
                    EpiduralUsageCard(deliveries: deliveries).frame(maxWidth: .infinity, minHeight: 50)
                    NICUStayCard(deliveries: deliveries).frame(maxWidth: .infinity, minHeight: 50)
                }
            case .babyCount: BabyCountCard(deliveries: deliveries)
            case .babyMeasurements: BabyMeasurementsCard(deliveries: deliveries)
            case .sexDistribution: SexDistributionCard(deliveries: deliveries)
            case .timeOfDay: TimeOfDayCard(deliveries: deliveries)
            case .dayOfWeek: DayOfWeekCard(deliveries: deliveries)
            case .yearOverYear: YearOverYearCard(deliveries: deliveries)
            case .personalBests: PersonalBestsCard(deliveries: deliveries)
            }
        }
    }
}
#endif
