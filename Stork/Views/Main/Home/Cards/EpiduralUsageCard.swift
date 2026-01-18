//
//  EpiduralUsageCard.swift
//  Stork
//
//  Created by Nick Molargik on 11/3/25.
//

import SwiftUI
import SwiftData

struct EpiduralUsageCard: View {
    @Environment(DeliveryManager.self) private var deliveryManager: DeliveryManager
    let viewModel: HomeView.ViewModel

    var body: some View {
        InsightCard(title: "Epidural", systemImage: "syringe.fill", accent: Color.red) {
            let percentage = viewModel.epiduralUsagePercentage(deliveries: deliveryManager.deliveries)
            AnimatedPercentage(value: percentage, font: .title2, fontWeight: .bold)
                .accessibilityLabel("Epidural usage: \(String(format: "%.1f", percentage)) percent of deliveries")
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
    
    EpiduralUsageCard(viewModel: HomeView.ViewModel())
        .environment(DeliveryManager(context: context))
}
