//
//  BabyMeasurementsCard.swift
//  Stork
//
//  Created by Nick Molargik on 11/3/25.
//

import SwiftUI
import SwiftData

struct BabyMeasurementsCard: View {
    @Environment(DeliveryManager.self) private var deliveryManager: DeliveryManager
    @AppStorage(AppStorageKeys.useMetricUnits) private var useMetricUnits: Bool = false
    let viewModel: HomeView.ViewModel

    var body: some View {
        InsightCard(title: "Baby Measurements", systemImage: "ruler", accent: .storkOrange) {
            let stats = viewModel.babyMeasurementStats(deliveries: deliveryManager.deliveries)
            VStack(alignment: .leading, spacing: 12) {
                // Stat chips
                HStack(spacing: 8) {
                    HStack(spacing: 6) {
                        Image(systemName: "scalemass.fill")
                        VStack(alignment: .leading, spacing: 0) {
                            Text("Avg Weight").font(.caption2).foregroundStyle(.secondary)
                            Text(weightDisplay(stats.averageWeight)).font(.subheadline).fontWeight(.semibold)
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(.ultraThinMaterial, in: Capsule())
                    .foregroundStyle(.black)

                    HStack(spacing: 6) {
                        Image(systemName: "ruler.fill")
                        VStack(alignment: .leading, spacing: 0) {
                            Text("Avg Height").font(.caption2).foregroundStyle(.secondary)
                            Text(heightDisplay(stats.averageHeight)).font(.subheadline).fontWeight(.semibold)
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(.ultraThinMaterial, in: Capsule())
                    .foregroundStyle(.black)
                }

                if stats.count == 0 {
                    Label("No babies logged yet.", systemImage: "tray.fill")
                        .foregroundStyle(.secondary)
                        .labelStyle(.titleOnly)
                }
            }
        }
    }

    private func weightDisplay(_ ounces: Double) -> String {
        if useMetricUnits {
            let grams = ounces * 28.349523125
            return "\(Int(round(grams))) g"
        } else {
            return "\(String(format: "%.1f", ounces)) oz"
        }
    }

    private func heightDisplay(_ inches: Double) -> String {
        if useMetricUnits {
            let cm = inches * 2.54
            return "\(String(format: "%.1f", cm)) cm"
        } else {
            return "\(String(format: "%.1f", inches)) in"
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
    
    BabyMeasurementsCard(viewModel: HomeView.ViewModel())
        .environment(DeliveryManager(context: context))
}
