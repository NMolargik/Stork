//
//  NICUStayCard.swift
//  StorkFeatureDashboard
//

#if os(iOS)
import SwiftUI
import StorkCore
import StorkDesignSystem

struct NICUStayCard: View {
    let deliveries: [Delivery]

    var body: some View {
        InsightCard(title: String(localized: "NICU Stays", bundle: .module), systemImage: "bed.double", accent: .red) {
            let percentage = DeliveryStatistics.nicuStayPercentage(deliveries: deliveries)
            AnimatedPercentage(value: percentage, font: .title2, fontWeight: .bold)
                .accessibilityLabel("NICU stays: \(String(format: "%.1f", percentage)) percent of babies")
        }
    }
}
#endif
