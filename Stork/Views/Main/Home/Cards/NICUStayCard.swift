//
//  NICUStayCard.swift
//  Stork
//
//  Created by Nick Molargik on 11/3/25.
//

import SwiftUI
import SwiftData

struct NICUStayCard: View {
    @Environment(DeliveryManager.self) private var deliveryManager: DeliveryManager
    let viewModel: HomeView.ViewModel

    var body: some View {
        InsightCard(title: "NICU Stays", systemImage: "bed.double", accent: Color.red) {
            let percentage = viewModel.nicuStayPercentage(deliveries: deliveryManager.deliveries)
            AnimatedPercentage(value: percentage, font: .title2, fontWeight: .bold)
                .accessibilityLabel("N I C U stays: \(String(format: "%.1f", percentage)) percent of babies")
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
    
    NICUStayCard(viewModel: HomeView.ViewModel())
        .environment(DeliveryManager(context: context))
}
