import SwiftUI
import Charts
import SwiftData

struct HomeView: View {
    @Environment(DeliveryManager.self) private var deliveryManager: DeliveryManager
    @Environment(InsightManager.self) private var insightManager: InsightManager
    
    @AppStorage(AppStorageKeys.useMetricUnits) private var useMetricUnits: Bool = false
    
    @Binding var showingEntrySheet: Bool
    @State private var jarShuffle = false
    @State private var viewModel = ViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                let monthly = viewModel.monthlyJarCounts(deliveries: deliveryManager.deliveries)
                let monthlyKey = "\(monthly.boy)-\(monthly.girl)-\(monthly.loss)"
                JarView(boyCount: monthly.boy, girlCount: monthly.girl, lossCount: monthly.loss, reshuffle: $jarShuffle)
                    .id(monthlyKey)
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
        
        .environment(deliveryManager)
        .environment(insightManager)
    }
    
    // (monthlyJarCounts helper removed)
}

// MARK: - Delivery Method Distribution Card


// MARK: - Epidural Usage Card

// MARK: - Baby Count Trends Card
struct BabyCountCard: View {
    @Environment(DeliveryManager.self) private var deliveryManager: DeliveryManager
    let viewModel: HomeView.ViewModel

    var body: some View {
        InsightCard(title: "Babies per Delivery", systemImage: "figure.2.and.child.holdinghands", accent: .storkPink) {
            let average = viewModel.averageBabyCount(deliveries: deliveryManager.deliveries)
            let monthlyCounts = viewModel.monthlyBabyCounts(deliveries: deliveryManager.deliveries)
            let totals = viewModel.deliveryAndBabyTotals(deliveries: deliveryManager.deliveries)
            let totalDeliveries = totals.deliveries
            let totalBabies = totals.babies

            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Average")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("\(String(format: "%.1f", average)) babies / delivery")
                        .font(.title3)
                        .fontWeight(.semibold)
                    Text("Deliveries: \(totalDeliveries) • Babies: \(totalBabies)")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                if !monthlyCounts.labels.isEmpty {
                    Chart {
                        ForEach(Array(zip(monthlyCounts.labels, monthlyCounts.counts)), id: \.0) { label, count in
                            AreaMark(
                                x: .value("Month", label),
                                y: .value("Babies", count)
                            )
                            .foregroundStyle(LinearGradient(colors: [.storkPink.opacity(0.35), .clear], startPoint: .top, endPoint: .bottom))
                            .interpolationMethod(.catmullRom)

                            LineMark(
                                x: .value("Month", label),
                                y: .value("Babies", count)
                            )
                            .foregroundStyle(.storkPink)
                            .interpolationMethod(.catmullRom)
                            .symbol(Circle())
                            .symbolSize(30)
                        }
                    }
                    .frame(height: 200)
                    .chartYAxis {
                        AxisMarks(position: .leading, values: .automatic) { value in
                            AxisValueLabel(value.as(Int.self)!.description)
                        }
                    }
                    .chartXAxis {
                        AxisMarks(values: monthlyCounts.labels) { value in
                            AxisValueLabel(anchor: .bottom) {
                                if let label = value.as(String.self) {
                                    Text(label).rotationEffect(.degrees(45))
                                }
                            }
                        }
                    }
                } else {
                    Label("No deliveries logged yet.", systemImage: "tray.fill")
                        .foregroundStyle(.secondary)
                        .labelStyle(.titleOnly)
                }
            }
        }
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
