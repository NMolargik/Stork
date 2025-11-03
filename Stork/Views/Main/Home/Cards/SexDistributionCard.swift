//
//  SexDistributionCard.swift
//  Stork
//
//  Created by Nick Molargik on 11/3/25.
//

import SwiftUI
import SwiftData
import Charts

struct SexDistributionCard: View {
    @Environment(DeliveryManager.self) private var deliveryManager: DeliveryManager
    let viewModel: HomeView.ViewModel

    var body: some View {
        InsightCard(title: "Sex Distribution", systemImage: "chart.pie.fill", accent: .storkPurple) {
            let stats = viewModel.sexDistribution(deliveries: deliveryManager.deliveries)
            VStack(alignment: .leading, spacing: 10) {
                // Stat chips
                HStack(spacing: 8) {
                    HStack(spacing: 6) {
                        Image(systemName: "circle.fill")
                        VStack(alignment: .leading, spacing: 0) {
                            Text("Male").font(.caption2).foregroundStyle(.secondary)
                            Text("\(String(format: "%.0f", stats.malePercentage))%").font(.subheadline).fontWeight(.semibold)
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(.ultraThinMaterial, in: Capsule())
                    .foregroundStyle(.storkBlue)

                    HStack(spacing: 6) {
                        Image(systemName: "circle.fill")
                        VStack(alignment: .leading, spacing: 0) {
                            Text("Female").font(.caption2).foregroundStyle(.secondary)
                            Text("\(String(format: "%.0f", stats.femalePercentage))%").font(.subheadline).fontWeight(.semibold)
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(.ultraThinMaterial, in: Capsule())
                    .foregroundStyle(.storkPink)

                    HStack(spacing: 6) {
                        Image(systemName: "circle.fill")
                        VStack(alignment: .leading, spacing: 0) {
                            Text("Loss").font(.caption2).foregroundStyle(.secondary)
                            Text("\(String(format: "%.0f", stats.lossPercentage))%").font(.subheadline).fontWeight(.semibold)
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(.ultraThinMaterial, in: Capsule())
                    .foregroundStyle(.storkPurple)
                }
                if stats.total > 0 {
                    ZStack {
                        Chart {
                            ForEach([
                                ("Male", stats.maleCount, Color.storkBlue),
                                ("Female", stats.femaleCount, Color.storkPink),
                                ("Loss", stats.lossCount, Color.storkPurple)
                            ], id: \.0) { label, count, color in
                                SectorMark(
                                    angle: .value("Count", count),
                                    innerRadius: .ratio(0.52),
                                    angularInset: 1.0
                                )
                                .foregroundStyle(color)
                            }
                        }
                        .frame(height: 220)

                        VStack(spacing: 2) {
                            Text("Babies")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("\(stats.total)")
                                .font(.title2).bold()
                        }
                        .allowsHitTesting(false)
                    }
                } else {
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
    
    SexDistributionCard(viewModel: HomeView.ViewModel())
        .environment(DeliveryManager(context: context))
}

