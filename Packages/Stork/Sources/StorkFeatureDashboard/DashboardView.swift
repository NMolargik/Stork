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
                        VStack(spacing: 16) { ForEach(columnCards(even: true)) { CardView(card: $0, deliveries: model.deliveries) } }
                        VStack(spacing: 16) { ForEach(columnCards(even: false)) { CardView(card: $0, deliveries: model.deliveries) } }
                    }
                } else {
                    ForEach(model.cardOrder) { CardView(card: $0, deliveries: model.deliveries) }
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

    private struct JarSection: View {
        var model: DashboardModel
        @Binding var jarShuffle: Bool

        var body: some View {
            let monthly = model.monthlyJarCounts
            JarView(
                boyCount: monthly.boy,
                girlCount: monthly.girl,
                lossCount: monthly.loss,
                history: AnyView(JarHistoryView(deliveries: model.deliveries)),
                reshuffle: $jarShuffle
            )
            .id(WeekMath.startOfMonth(for: Date()))
            .frame(height: 250)
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
