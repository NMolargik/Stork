//
//  EpiduralUsageCard.swift
//  StorkFeatureDashboard
//

#if os(iOS)
import SwiftUI
import StorkCore
import StorkDesignSystem

struct EpiduralUsageCard: View {
    let deliveries: [Delivery]

    var body: some View {
        InsightCard(title: String(localized: "Epidural", bundle: .module), systemImage: "syringe.fill", accent: .red) {
            let percentage = DeliveryStatistics.epiduralUsagePercentage(deliveries: deliveries)
            AnimatedPercentage(value: percentage, font: .title2, fontWeight: .bold)
                .accessibilityLabel("Epidural usage: \(String(format: "%.1f", percentage)) percent of deliveries")
        }
    }
}
#endif
