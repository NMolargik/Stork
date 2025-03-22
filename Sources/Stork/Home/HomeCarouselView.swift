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
    
    @ObservedObject var deliveryViewModel: DeliveryViewModel
    
    @State private var selectedIndex: Int = 0

    #if !SKIP
    init(deliveryViewModel: DeliveryViewModel) {
        self.deliveryViewModel = deliveryViewModel
        
        UIPageControl.appearance().currentPageIndicatorTintColor = UIColor(Color("storkIndigo"))
        UIPageControl.appearance().pageIndicatorTintColor = UIColor.gray
       }
    #endif
    
    var body: some View {
        VStack {
            TabView(selection: $selectedIndex) {
                #if !SKIP
                DeliveriesThisWeekView(deliveries: $deliveryViewModel.deliveries)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .backgroundCard(colorScheme: colorScheme)
                    .padding(.vertical, 5)
                    .tag(0)
                
                DeliveriesLastSixMonthsView(groupedDeliveries: $deliveryViewModel.groupedDeliveries)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .backgroundCard(colorScheme: colorScheme)
                    .padding(.vertical, 5)
                    .tag(1)
                #endif
                
                BabySexDistributionView(groupedDeliveries: $deliveryViewModel.groupedDeliveries)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .backgroundCard(colorScheme: colorScheme)
                    .padding(.vertical, 5)
                    .tag(2)
                
                TotalWeightAndLengthStatsView(groupedDeliveries: $deliveryViewModel.groupedDeliveries)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .backgroundCard(colorScheme: colorScheme)
                    .padding(.vertical, 5)
                    .tag(3)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.horizontal, -5)
            
            // Custom page indicators (moves dots below the content)
            HStack(spacing: 6) {
                ForEach(0..<4, id: \.self) { index in
                    Circle()
                        .fill(index == selectedIndex ? Color("storkIndigo") : Color.gray.opacity(0.5))
                        .frame(width: 8, height: 8)
                        .animation(.easeInOut, value: selectedIndex)
                }
            }
            .padding(.top, 5)
        }
        .ignoresSafeArea(edges: .bottom)
    }
}

#Preview {
    HomeCarouselView(
        deliveryViewModel: DeliveryViewModel(deliveryRepository: MockDeliveryRepository())
    )
}
