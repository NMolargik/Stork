//
//  MusterCarouselView.swift
//  skipapp-stork
//
//  Created by Nick Molargik on 12/31/24.
//

import SwiftUI
import StorkModel

struct MusterCarouselView: View {
    @AppStorage(StorageKeys.useDarkMode) var useDarkMode: Bool = false
    
    @ObservedObject var deliveryViewModel: DeliveryViewModel

    @State private var selectedIndex: Int = 0
    
    #if !SKIP
    init(deliveryViewModel: DeliveryViewModel) {
        self.deliveryViewModel = deliveryViewModel
        self._selectedIndex = State(initialValue: 0)
        
        UIPageControl.appearance().currentPageIndicatorTintColor = UIColor(Color("storkIndigo"))
        UIPageControl.appearance().pageIndicatorTintColor = UIColor.gray
    }
    #endif
    
    var body: some View {
        VStack {
            TabView(selection: $selectedIndex) {
            #if !SKIP
                DeliveriesThisWeekView(deliveries: $deliveryViewModel.musterDeliveries)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .backgroundCard(colorScheme: useDarkMode ? .dark : .light)
                    .padding(.vertical, 5)
                    .tag(0)
            #endif
                
            #if !SKIP
                DeliveriesLastSixMonthsView(groupedDeliveries: $deliveryViewModel.groupedMusterDeliveries)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .backgroundCard(colorScheme: useDarkMode ? .dark : .light)
                    .padding(.vertical, 5)
                    .tag(1)
            #endif
                
                BabySexDistributionView(groupedDeliveries: $deliveryViewModel.groupedMusterDeliveries)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .backgroundCard(colorScheme: useDarkMode ? .dark : .light)
                    .padding(.vertical, 5)
                    .tag(2)
                
                TotalWeightAndLengthStatsView(groupedDeliveries: $deliveryViewModel.groupedMusterDeliveries)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .backgroundCard(colorScheme: useDarkMode ? .dark : .light)
                    .padding(.vertical, 5)
                    .tag(3)
            }
            .tabViewStyle(.page(indexDisplayMode: .never)) // Hide built-in indicators
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Custom page indicators (moves dots below the content)
            HStack(spacing: 6) {
                ForEach(0..<4, id: \.self) { index in
                    Circle()
                        .fill(index == selectedIndex ? Color("storkIndigo") : Color.gray.opacity(0.5))
                        .frame(width: 8, height: 8)
                        .animation(.easeInOut, value: selectedIndex)
                }
            }
        }
        .ignoresSafeArea(edges: .bottom)
    }
}

#Preview {
    MusterCarouselView(
        deliveryViewModel: DeliveryViewModel(deliveryRepository: MockDeliveryRepository())
    )
}
