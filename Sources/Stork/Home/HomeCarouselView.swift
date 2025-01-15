//
//  HomeCarouselView.swift
//  skipapp-stork
//
//  Created by Nick Molargik on 12/31/24.
//

import SwiftUI
import StorkModel

struct HomeCarouselView: View {
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var deliveryViewModel: DeliveryViewModel

    private let numberOfCards = 4 // Update this if you add or remove graphs

    var body: some View {
        VStack {
            TabView {
                ForEach(0..<numberOfCards, id: \.self) { index in
                    carouselCard(for: index)
                }
            }
            .tabViewStyle(.page) // Carousel style with page dots
            .frame(height: 220) // Consistent height for carousel

            // Dot Indicators (if you want to customize instead of relying on default)
            /*
            HStack(spacing: 8) {
                ForEach(0..<numberOfCards, id: \.self) { index in
                    Circle()
                        .fill(currentIndex == index ? Color.primary : Color.secondary.opacity(0.5))
                        .frame(width: 10, height: 10)
                }
            }
            .padding(.top, 8)
            */
        }
        .onAppear {
            // Additional initialization if needed
        }
    }

    // MARK: - Helper Methods
    private func carouselCard(for index: Int) -> some View {
        ZStack {
            Group {
                if index == 0 {
                    #if !SKIP
                    DeliveriesThisWeekView(deliveries: $deliveryViewModel.deliveries)
                    #endif
                } else if index == 1 {
                    #if !SKIP
                    DeliveriesLastSixMonthsView(groupedDeliveries: $deliveryViewModel.groupedDeliveries)
                    #endif
                } else if index == 2 {
                    BabySexDistributionView(groupedDeliveries: $deliveryViewModel.groupedDeliveries)
                } else if index == 3 {
                    TotalWeightAndLengthStatsView(groupedDeliveries: $deliveryViewModel.groupedDeliveries)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity) // Ensure consistent card content size
            .backgroundCard(colorScheme: colorScheme) // Consistent card styling
            .padding(.vertical, 5)
        }
    }
}

#Preview {
    HomeCarouselView()
        .environmentObject(DeliveryViewModel(deliveryRepository: MockDeliveryRepository()))
}
