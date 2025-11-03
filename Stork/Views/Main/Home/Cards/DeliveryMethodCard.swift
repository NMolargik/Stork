//
//  DeliveryMethodCard.swift
//  Stork
//
//  Created by Nick Molargik on 11/3/25.
//

import SwiftUI
import SwiftData

struct DeliveryMethodCard: View {
    @Environment(DeliveryManager.self) private var deliveryManager: DeliveryManager
    let viewModel: HomeView.ViewModel

    var body: some View {
        InsightCard(title: "Delivery Method", systemImage: "hands.and.sparkles.fill", accent: .storkBlue) {
            let stats = viewModel.deliveryMethodStats(deliveries: deliveryManager.deliveries)
            VStack(alignment: .leading, spacing: 12) {
                if stats.total > 0 {
                    // Percentages
                    let v = stats.vaginalPercentage
                    let c = stats.cSectionPercentage
                    let vb = stats.vBacPercentage

                    // Stacked percentage bar
                    GeometryReader { geo in
                        let w = geo.size.width
                        ZStack {
                            Capsule()
                                .fill(.ultraThinMaterial)
                            HStack(spacing: 0) {
                                Rectangle()
                                    .frame(width: w * CGFloat(v / 100.0))
                                    .foregroundStyle(.storkBlue)
                                Rectangle()
                                    .frame(width: w * CGFloat(c / 100.0))
                                    .foregroundStyle(.storkOrange)
                                Rectangle()
                                    .frame(width: w * CGFloat(vb / 100.0))
                                    .foregroundStyle(.storkPurple)
                            }
                            .frame(height: 14)
                            .clipShape(Capsule())
                            Capsule()
                                .strokeBorder(.white.opacity(0.12))
                        }
                    }
                    .frame(height: 16)

                    // Legend and actual values
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 8) {
                            Label("Vaginal \(String(format: "%.0f", v))%", systemImage: "circle.fill")
                                .foregroundStyle(.storkBlue)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(.ultraThinMaterial, in: Capsule())

                            Label("C-Section \(String(format: "%.0f", c))%", systemImage: "circle.fill")
                                .foregroundStyle(.storkOrange)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(.ultraThinMaterial, in: Capsule())

                            Label("VBAC \(String(format: "%.0f", vb))%", systemImage: "circle.fill")
                                .foregroundStyle(.storkPurple)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(.ultraThinMaterial, in: Capsule())
                        }
                        .font(.caption)
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
    
    DeliveryMethodCard(viewModel: HomeView.ViewModel())
        .environment(DeliveryManager(context: context))
}
