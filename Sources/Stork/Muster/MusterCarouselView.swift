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

    @State private var selectedIndex: Int = 0
    
    #if !SKIP
    init() {
        UIPageControl.appearance().currentPageIndicatorTintColor = UIColor(Color.indigo)
        UIPageControl.appearance().pageIndicatorTintColor = UIColor.gray
       }
    #endif
    
    var body: some View {
        VStack {
            TabView(selection: $selectedIndex) {
            #if !SKIP
                DeliveriesThisWeekView(deliveries: $deliveryViewModel.musterDeliveries)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .backgroundCard(colorScheme: colorScheme)
                    .padding(.vertical, 5)
                    .tag(0)
#endif
                
#if !SKIP
                DeliveriesLastSixMonthsView(groupedDeliveries: $deliveryViewModel.groupedMusterDeliveries)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .backgroundCard(colorScheme: colorScheme)
                    .padding(.vertical, 5)
                    .tag(1)
#endif
                
                BabySexDistributionView(groupedDeliveries: $deliveryViewModel.groupedMusterDeliveries)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .backgroundCard(colorScheme: colorScheme)
                    .padding(.vertical, 5)
                    .tag(2)
                
                TotalWeightAndLengthStatsView(groupedDeliveries: $deliveryViewModel.groupedMusterDeliveries)
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
    MusterCarouselView()
        .environmentObject(DeliveryViewModel(deliveryRepository: MockDeliveryRepository()))
}
