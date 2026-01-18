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

                    // Animated stacked percentage bar
                    AnimatedProgressBar(segments: [
                        .init(value: v, color: .storkBlue),
                        .init(value: c, color: .storkOrange),
                        .init(value: vb, color: .storkPurple)
                    ])
                    .accessibilityHidden(true)

                    // Legend with animated percentages
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 8) {
                            methodPill(label: "Vaginal", value: v, color: .storkBlue)
                            methodPill(label: "C-Section", value: c, color: .storkOrange)
                            methodPill(label: "VBAC", value: vb, color: .storkPurple)
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

    @ViewBuilder
    private func methodPill(label: String, value: Double, color: Color) -> some View {
        HStack(spacing: 4) {
            Image(systemName: "circle.fill")
                .font(.caption2)
            Text(label)
            AnimatedNumber(value: value, format: "%.0f", font: .caption, fontWeight: .regular, color: color)
            Text("%")
        }
        .foregroundStyle(color)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(.ultraThinMaterial, in: Capsule())
        .accessibilityLabel("\(label) deliveries: \(String(format: "%.0f", value)) percent")
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
