import SwiftUI
import Charts
import SwiftData

struct HomeView: View {
    @Environment(DeliveryManager.self) private var deliveryManager: DeliveryManager
    @Environment(InsightManager.self) private var insightManager: InsightManager
    @Environment(\.horizontalSizeClass) private var hSizeClass
    
    @AppStorage(AppStorageKeys.useMetricUnits) private var useMetricUnits: Bool = false
    
    @Binding var showingEntrySheet: Bool
    @State private var jarShuffle = false
    @State private var viewModel = ViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                let monthly = viewModel.monthlyJarCounts(deliveries: deliveryManager.deliveries)
                // Only recreate the JarView when the calendar month changes, not when counts change
                let monthKey: String = {
                    let df = DateFormatter()
                    df.dateFormat = "yyyy-MM"
                    return df.string(from: Date())
                }()
                JarView(boyCount: monthly.boy, girlCount: monthly.girl, lossCount: monthly.loss, reshuffle: $jarShuffle)
                    .id(monthKey)
                    .frame(height: 250)

                DeliveryMethodCard(viewModel: viewModel)
                HStack(spacing: 12) {
                    EpiduralUsageCard(viewModel: viewModel)
                        .frame(maxWidth: .infinity, minHeight: 50)
                    NICUStayCard(viewModel: viewModel)
                        .frame(maxWidth: .infinity, minHeight: 50)
                }
                BabyCountCard(viewModel: viewModel)
                BabyMeasurementsCard(viewModel: viewModel)
                SexDistributionCard(viewModel: viewModel)
            }
            .padding(.horizontal)
            .padding(.bottom, 20)
        }
        .refreshable {
            // Only refresh the marble jar; the rest of the Home screen stays as-is
            jarShuffle = true
        }
        .environment(deliveryManager)
        .environment(insightManager)
    }
}

#Preview {
    let container: ModelContainer = {
        let schema = Schema([Delivery.self, User.self, Baby.self])
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        return try! ModelContainer(for: schema, configurations: [configuration])
    }()
    let context = ModelContext(container)
    
    
    HomeView(showingEntrySheet: .constant(false))
        .environment(DeliveryManager(context: context))
        .environment(InsightManager(deliveryManager: DeliveryManager(context: context)))
}
