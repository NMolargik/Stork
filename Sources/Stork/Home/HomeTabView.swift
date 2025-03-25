//
//  HomeTabView.swift
//
//
//  Created by Nick Molargik on 11/30/24.
//

import SwiftUI
import StorkModel

struct HomeTabView: View {
    @EnvironmentObject var appStateManager: AppStateManager
    @EnvironmentObject var appStorageManager: AppStorageManager
    
    @ObservedObject var deliveryViewModel: DeliveryViewModel

    var body: some View {
        NavigationStack(path: $appStateManager.navigationPath) {
            VStack {
                HStack {
                    Text("Stork")
                        .font(.largeTitle).fontWeight(.bold)
                        .padding(.trailing, 5)
                        .foregroundStyle(appStorageManager.useDarkMode ? Color.white : Color.black)
                    Spacer()
                }
                
                HomeTimeView()
                
                HomeBodyView(deliveries: $deliveryViewModel.deliveries, startNewDelivery: deliveryViewModel.startNewDelivery)
                    .frame(maxWidth: .infinity)

                
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
    .environmentObject(AppStorageManager())
}
