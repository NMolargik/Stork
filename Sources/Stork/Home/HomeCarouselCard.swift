//
//  HomeCarouselCard.swift
//  skipapp-stork
//
//  Created by Nick Molargik on 1/22/25.
//

import SwiftUI

// MARK: - Enum for Cards
enum HomeCarouselCard: CaseIterable {
    case deliveriesThisWeek, deliveriesLastSixMonths, babySexDistribution, totalWeightAndLengthStats

    @MainActor @ViewBuilder
    func view(deliveryViewModel: DeliveryViewModel) -> some View {
        switch self {
        case .deliveriesThisWeek:
            #if !SKIP
            DeliveriesThisWeekView(deliveries: deliveryViewModel.deliveries) // ✅ FIXED
            #endif
        case .deliveriesLastSixMonths:
            #if !SKIP
            DeliveriesLastSixMonthsView(groupedDeliveries: deliveryViewModel.groupedDeliveries)
            #endif
        case .babySexDistribution:
            BabySexDistributionView(groupedDeliveries: deliveryViewModel.groupedDeliveries)
        case .totalWeightAndLengthStats:
            TotalWeightAndLengthStatsView(groupedDeliveries: deliveryViewModel.groupedDeliveries)
        }
    }
}

