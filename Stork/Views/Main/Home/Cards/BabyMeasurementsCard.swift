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
                            .accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: 0) {
                            Text("Avg Weight").font(.caption2)
                            Text(UnitConversion.weightDisplay(stats.averageWeight, useMetric: useMetricUnits)).font(.subheadline).fontWeight(.semibold)
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(.ultraThinMaterial, in: Capsule())
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Average weight: \(UnitConversion.weightDisplay(stats.averageWeight, useMetric: useMetricUnits))")

                    HStack(spacing: 6) {
                        Image(systemName: "ruler.fill")
                            .accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: 0) {
                            Text("Avg Height").font(.caption2)
                            Text(UnitConversion.heightDisplay(stats.averageHeight, useMetric: useMetricUnits)).font(.subheadline).fontWeight(.semibold)
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(.ultraThinMaterial, in: Capsule())
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Average height: \(UnitConversion.heightDisplay(stats.averageHeight, useMetric: useMetricUnits))")
                }

                if stats.count == 0 {
                    Label("No babies logged yet.", systemImage: "tray.fill")
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
    
    BabyMeasurementsCard(viewModel: HomeView.ViewModel())
        .environment(DeliveryManager(context: context))
}
