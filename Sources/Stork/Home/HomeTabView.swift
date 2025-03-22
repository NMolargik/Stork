//
//  HomeTabView.swift
//
//
//  Created by Nick Molargik on 11/30/24.
//

import SwiftUI
import StorkModel

struct HomeTabView: View {
    @Environment(\.colorScheme) var colorScheme
    
    @EnvironmentObject var appStateManager: AppStateManager
    
    @ObservedObject var deliveryViewModel: DeliveryViewModel

    var body: some View {
        NavigationStack(path: $appStateManager.navigationPath) {
            VStack {
                HStack {
                    Text("Stork")
                        .font(.largeTitle).fontWeight(.bold)
                        .padding(.trailing, 5)
                    Spacer()
                }
                
                HomeWeekView()
                HomeBodyView(deliveries: $deliveryViewModel.deliveries, startNewDelivery: deliveryViewModel.startNewDelivery)
                HomeCarouselView(deliveryViewModel: deliveryViewModel)
                
                Spacer()
            }
            .padding()
        }
    }
}

// MARK: - Preview
#Preview {
    HomeTabView(
        deliveryViewModel: DeliveryViewModel(deliveryRepository: MockDeliveryRepository())
    )
    .environmentObject(AppStateManager.shared)
}
