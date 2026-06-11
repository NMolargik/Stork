import SwiftUI
import Charts
import SwiftData
import UIKit

struct DashboardView: View {
    @Environment(DeliveryManager.self) private var deliveryManager: DeliveryManager
    @Environment(ExportManager.self) private var exportManager: ExportManager
    @Environment(CloudSyncManager.self) private var cloudSyncManager: CloudSyncManager
    @Environment(\.horizontalSizeClass) private var hSizeClass

    @AppStorage(AppStorageKeys.useMetricUnits) private var useMetricUnits: Bool = false

    @Binding var showingEntrySheet: Bool
    @Binding var showingReorderSheet: Bool
    @State private var jarShuffle = false
    @State private var viewModel = ViewModel()
    @State private var shareImage: UIImage?
    @State private var showShareSheet = false
    @State private var cardOrder: [DashboardCard] = DashboardCard.loadOrder()

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // JarView always at top
                jarViewSection

                // Dynamic card order: one column in compact width, two
                // balanced columns when there's room (iPad, Mac, visionOS,
                // resized iPhone windows).
                if hSizeClass == .regular {
                    HStack(alignment: .top, spacing: 16) {
                        VStack(spacing: 16) {
                            ForEach(columnCards(even: true)) { card in
                                cardView(for: card)
                            }
                        }
                        VStack(spacing: 16) {
                            ForEach(columnCards(even: false)) { card in
                                cardView(for: card)
                            }
                        }
                    }
                } else {
                    ForEach(cardOrder) { card in
                        cardView(for: card)
                    }
                }
            }
            .frame(maxWidth: 1000)
            .frame(maxWidth: .infinity)
            .padding(.horizontal)
            .padding(.bottom, 20)
        }
        .refreshable {
            jarShuffle = true
            await cloudSyncManager.triggerSync()
            await deliveryManager.refresh()
        }
        .sheet(isPresented: $showShareSheet) {
            if let image = shareImage {
                ShareSheet(items: [image])
            }
        }
        .sheet(isPresented: $showingReorderSheet) {
            DashboardCardOrderSheet(currentOrder: cardOrder) { newOrder in
                cardOrder = newOrder
            }
            .presentationDetents([.large])
        }
        .onAppear {
            cardOrder = DashboardCard.loadOrder()
        }
    }

    // MARK: - View Sections

    /// Splits the user's card order into two columns by alternating, so
    /// reordering still reads left-to-right, top-to-bottom in regular width.
    private func columnCards(even: Bool) -> [DashboardCard] {
        cardOrder.enumerated()
            .filter { ($0.offset % 2 == 0) == even }
            .map(\.element)
    }

    @ContentBuilder
    private var jarViewSection: some View {
        let monthly = viewModel.monthlyJarCounts(deliveries: deliveryManager.deliveries)
        JarView(boyCount: monthly.boy, girlCount: monthly.girl, lossCount: monthly.loss, reshuffle: $jarShuffle)
            .id(WeekMath.startOfMonth(for: Date()))
            .frame(height: 250)
    }

    @ContentBuilder
    private func cardView(for card: DashboardCard) -> some View {
        switch card {
        case .deliveryMethod:
            DeliveryMethodCard(viewModel: viewModel)
                .contextMenu { shareContextMenu(for: .deliveryMethod) }
        case .epiduralNicu:
            HStack(spacing: 12) {
                EpiduralUsageCard(viewModel: viewModel)
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .contextMenu { shareContextMenu(for: .epiduralUsage) }
                NICUStayCard(viewModel: viewModel)
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .contextMenu { shareContextMenu(for: .nicuStay) }
            }
        case .babyCount:
            BabyCountCard(viewModel: viewModel)
                .contextMenu { shareContextMenu(for: .babyCount) }
        case .babyMeasurements:
            BabyMeasurementsCard(viewModel: viewModel)
                .contextMenu { shareContextMenu(for: .babyMeasurements) }
        case .sexDistribution:
            SexDistributionCard(viewModel: viewModel)
                .contextMenu { shareContextMenu(for: .sexDistribution) }
        case .timeOfDay:
            TimeOfDayCard(viewModel: viewModel)
        case .dayOfWeek:
            DayOfWeekCard(viewModel: viewModel)
        case .yearOverYear:
            YearOverYearCard(viewModel: viewModel)
        case .personalBests:
            PersonalBestsCard(viewModel: viewModel)
        }
    }

    @ContentBuilder
    private func shareContextMenu(for cardType: CardImageRenderer.CardType) -> some View {
        Button {
            shareCard(cardType)
        } label: {
            Label("Share Card", systemImage: "square.and.arrow.up")
        }
    }

    private func shareCard(_ cardType: CardImageRenderer.CardType) {
        shareImage = exportManager.renderStatCard(
            type: cardType,
            deliveries: deliveryManager.deliveries,
            useMetricUnits: useMetricUnits,
            includeWatermark: true
        )
        if shareImage != nil {
            Haptics.lightImpact()
            showShareSheet = true
        }
    }
}

// MARK: - Share Sheet
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    let container: ModelContainer = {
        let schema = Schema([Delivery.self, Baby.self])
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        return try! ModelContainer(for: schema, configurations: [configuration])
    }()

    DashboardView(showingEntrySheet: .constant(false), showingReorderSheet: .constant(false))
        .environment(DeliveryManager(container: container))
        .environment(ExportManager())
        .environment(CloudSyncManager())
}
