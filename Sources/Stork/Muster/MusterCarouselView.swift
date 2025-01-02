//
//  MusterCarouselView.swift
//  skipapp-stork
//
//  Created by Nick Molargik on 12/31/24.
//

import SwiftUI
import StorkModel

struct MusterCarouselView: View {
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var deliveryViewModel: DeliveryViewModel
    
    // Current index of the carousel
    @State private var currentIndex: Int = 0
    
    // Offset during dragging
    @State private var dragOffset: CGFloat = 0.0
    
    // Threshold to determine card transition
    private let threshold: CGFloat = 100.0
    
    private var graphsShown = 4
    
    var body: some View {
        GeometryReader { geometry in
            VStack {
                ZStack {
                    // HStack containing all carousel cards
                    HStack(spacing: 0) {
                        #if !SKIP
                        DeliveriesThisWeek(deliveries: $deliveryViewModel.musterDeliveries)
                            .frame(width: geometry.size.width - 20)
                            .background {
                                Rectangle()
                                    .foregroundStyle(colorScheme == .dark ? .black : .white)
                                    .cornerRadius(10)
                                    .shadow(color: colorScheme == .dark ? .gray : .black, radius: 5)
                                    .padding(5)
                            }
                            .padding(.leading, 25)
                        
                        DeliveriesLastSix(groupedDeliveries: $deliveryViewModel.groupedMusterDeliveries)
                            .frame(width: geometry.size.width - 20)
                            .background {
                                Rectangle()
                                    .foregroundStyle(colorScheme == .dark ? .black : .white)
                                    .cornerRadius(10)
                                    .shadow(color: colorScheme == .dark ? .gray : .black, radius: 5)
                                    .padding(5)
                            }
                            .padding(.leading, 20)
                        
                        BabySexDistributionView(groupedDeliveries: $deliveryViewModel.groupedMusterDeliveries)
                            .frame(width: geometry.size.width - 20)
                            .background {
                                Rectangle()
                                    .foregroundStyle(colorScheme == .dark ? .black : .white)
                                    .cornerRadius(10)
                                    .shadow(color: colorScheme == .dark ? .gray : .black, radius: 5)
                                    .padding(5)
                            }
                            .padding(.leading, 20)
                        
                        TotalWeightAndLength(groupedDeliveries: $deliveryViewModel.groupedMusterDeliveries)
                            .frame(width: geometry.size.width - 20)
                            .background {
                                Rectangle()
                                    .foregroundStyle(colorScheme == .dark ? .black : .white)
                                    .cornerRadius(10)
                                    .shadow(color: colorScheme == .dark ? .gray : .black, radius: 5)
                                    .padding(5)
                            }
                            .padding(.leading, 20)
                        #endif
                    }
                    .frame(width: geometry.size.width * CGFloat(graphsShown) - 50, height: 200, alignment: .leading)
                    .offset(x: -CGFloat(currentIndex) * geometry.size.width + dragOffset + geometry.size.width + 160)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                // Update dragOffset based on user drag
                                dragOffset = value.translation.width
                            }
                            .onEnded { value in
                                withAnimation(.easeInOut) {
                                    // Determine if the drag exceeds the threshold
                                    if value.translation.width < -threshold && currentIndex < graphsShown - 1 {
                                        // Swipe Left - Next Card
                                        currentIndex += 1
                                    } else if value.translation.width > threshold && currentIndex > 0 {
                                        // Swipe Right - Previous Card
                                        currentIndex -= 1
                                    }
                                    // Reset dragOffset after gesture ends
                                    dragOffset = 0
                                }
                            }
                    )
                }
                .frame(width: geometry.size.width)
                .clipped()
                
                // Dot Indicators
                HStack(spacing: 8) {
                    ForEach(0..<graphsShown, id: \.self) { index in
                        Circle()
                            .fill(currentIndex == index ? Color.primary : Color.secondary.opacity(0.5))
                            .frame(width: 10, height: 10)
                    }
                }
            }

        }
        .frame(height: 220)
    }
}

#Preview {
    MusterCarouselView()
        .environmentObject(DeliveryViewModel(deliveryRepository: MockDeliveryRepository()))
}
