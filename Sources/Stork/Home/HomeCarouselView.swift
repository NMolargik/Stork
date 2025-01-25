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
    
    @State private var selectedIndex: Int = 0

    #if !SKIP
    init() {
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
            .tabViewStyle(.page(indexDisplayMode: .always))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.horizontal, -5)
            
            Spacer()
        }
        .ignoresSafeArea(edges: .bottom)
    }
}

#Preview {
    HomeCarouselView()
        .environmentObject(DeliveryViewModel(deliveryRepository: MockDeliveryRepository()))
}
