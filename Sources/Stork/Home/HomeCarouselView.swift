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

    @State private var currentIndex: Int = 0
    @State private var dragOffset: CGFloat = 0.0
    private let threshold: CGFloat = 100.0
    private let numberOfCards = 4 // Update this if you add or remove graphs

    var body: some View {
        GeometryReader { geometry in
            let cardWidth = geometry.size.width * 0.95 // Consistent card width
            let spacing: CGFloat = 10
            let totalCardWidth = cardWidth + spacing

            VStack {
                ZStack {
                    ForEach(0..<numberOfCards, id: \.self) { index in
                        carouselCard(for: index)
                            .frame(width: cardWidth) // Consistent card size
                            .offset(x: calculateCardOffset(for: index, totalCardWidth: totalCardWidth))
                            .animation(.easeInOut, value: currentIndex) // Smooth animation when changing index
                    }
                }
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            dragOffset = value.translation.width
                        }
                        .onEnded { value in
                            withAnimation(.easeInOut) {
                                if value.translation.width < -threshold && currentIndex < numberOfCards - 1 {
                                    currentIndex += 1
                                } else if value.translation.width > threshold && currentIndex > 0 {
                                    currentIndex -= 1
                                }
                                dragOffset = 0
                            }
                        }
                )
                .frame(width: geometry.size.width) // Restrict visible area
                .clipped()

                // Dot Indicators
                HStack(spacing: 8) {
                    ForEach(0..<numberOfCards, id: \.self) { index in
                        Circle()
                            .fill(currentIndex == index ? Color.primary : Color.secondary.opacity(0.5))
                            .frame(width: 10, height: 10)
                    }
                }
                .padding(.top, 8)
            }
        }
        .frame(height: 220)
        .onAppear {
            currentIndex = 0
            dragOffset = 0
        }
    }

    // MARK: - Helper Methods
    private func calculateCardOffset(for index: Int, totalCardWidth: CGFloat) -> CGFloat {
        // Offset each card based on its position and the current index
        let centeredIndexOffset = CGFloat(index - currentIndex) * totalCardWidth
        return centeredIndexOffset + dragOffset
    }

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
