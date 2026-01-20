import SwiftUI
import Charts
import SwiftData
import UIKit

struct HomeView: View {
    @Environment(DeliveryManager.self) private var deliveryManager: DeliveryManager
    @Environment(InsightManager.self) private var insightManager: InsightManager
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
    @State private var cardOrder: [HomeCard] = HomeCard.loadOrder()

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // JarView always at top
                jarViewSection

                // Dynamic card order
                ForEach(cardOrder) { card in
                    cardView(for: card)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 20)
        }
        .refreshable {
            jarShuffle = true
            await cloudSyncManager.triggerSync()
            await deliveryManager.refresh()
            print("Pull to refresh - synced \(deliveryManager.deliveries.count) deliveries")
        }
        .environment(deliveryManager)
        .environment(insightManager)
        .sheet(isPresented: $showShareSheet) {
            if let image = shareImage {
                ShareSheet(items: [image])
            }
        }
        .sheet(isPresented: $showingReorderSheet) {
            HomeCardOrderSheet(currentOrder: cardOrder) { newOrder in
                cardOrder = newOrder
            }
            .presentationDetents([.large])
        }
        .onAppear {
            cardOrder = HomeCard.loadOrder()
        }
    }

    // MARK: - View Sections

    @ViewBuilder
    private var jarViewSection: some View {
        let monthly = viewModel.monthlyJarCounts(deliveries: deliveryManager.deliveries)
        let monthKey: String = {
            let df = DateFormatter()
            df.dateFormat = "yyyy-MM"
            return df.string(from: Date())
        }()
        JarView(boyCount: monthly.boy, girlCount: monthly.girl, lossCount: monthly.loss, reshuffle: $jarShuffle)
            .id(monthKey)
            .frame(height: 250)
    }

    @ViewBuilder
    private func cardView(for card: HomeCard) -> some View {
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

    @ViewBuilder
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
        let schema = Schema([Delivery.self, User.self, Baby.self])
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        return try! ModelContainer(for: schema, configurations: [configuration])
    }()
    let context = ModelContext(container)

    HomeView(showingEntrySheet: .constant(false), showingReorderSheet: .constant(false))
        .environment(DeliveryManager(context: context))
        .environment(InsightManager(deliveryManager: DeliveryManager(context: context)))
        .environment(ExportManager())
        .environment(CloudSyncManager())
}
