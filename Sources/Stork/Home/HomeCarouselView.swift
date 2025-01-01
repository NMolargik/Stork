//
//  HomeCarouselView.swift
//  skipapp-stork
//
//  Created by Nick Molargik on 12/31/24.
//

import SwiftUI
import StorkModel

struct HomeCarouselView: View {
    
    @EnvironmentObject var deliveryViewModel: DeliveryViewModel
    
    // Current index of the carousel
    @State private var currentIndex: Int = 0
    
    // Offset during dragging
    @State private var dragOffset: CGFloat = 0.0
    
    // Threshold to determine card transition
    private let threshold: CGFloat = 100.0
    
    private var graphsShown = 3
    
    var body: some View {
        GeometryReader { geometry in
            VStack {
                ZStack {
                    // HStack containing all carousel cards
                    HStack(spacing: 0) {
                        #if !SKIP
                        DeliveriesPerDay(deliveries: $deliveryViewModel.deliveries)
                            .frame(width: geometry.size.width, height: geometry.size.height * 0.6)
                        
                        DeliveriesPerMonth(groupedDeliveries: $deliveryViewModel.groupedDeliveries)
                            .frame(width: geometry.size.width, height: geometry.size.height * 0.6)
                        
                        Text("Sex Distribution")
                        #endif
                    }
                    .frame(width: geometry.size.width * CGFloat(graphsShown), alignment: .leading)
                    .offset(x: -CGFloat(currentIndex) * geometry.size.width + dragOffset + geometry.size.width)
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
                .frame(width: geometry.size.width, height: geometry.size.height * 0.6)
                .clipped()
                
                // Dot Indicators
                HStack(spacing: 8) {
                    ForEach(0..<graphsShown, id: \.self) { index in
                        Circle()
                            .fill(currentIndex == index ? Color.primary : Color.secondary.opacity(0.5))
                            .frame(width: 10, height: 10)
                    }
                }
                .padding(.top, 10)
            }
        }
        .frame(height: 250) // Adjust the overall carousel height as needed
    }
}

#Preview {
    HomeCarouselView()
        .environmentObject(DeliveryViewModel(deliveryRepository: MockDeliveryRepository()))
}
