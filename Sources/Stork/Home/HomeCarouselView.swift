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

    private let numberOfCards = HomeCarouselCard.allCases.count

    var body: some View {
        VStack {
            TabView {
                ForEach(HomeCarouselCard.allCases, id: \.self) { card in
                    carouselCard(for: card)
                }
            }
            .tabViewStyle(.page)
            .frame(height: 220)
        }
    }

    // MARK: - Helper Methods
    private func carouselCard(for card: HomeCarouselCard) -> some View {
        ZStack {
            card.view(deliveryViewModel: deliveryViewModel)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .backgroundCard(colorScheme: colorScheme)
                .padding(.vertical, 5)
        }
    }
}

#Preview {
    HomeCarouselView()
        .environmentObject(DeliveryViewModel(deliveryRepository: MockDeliveryRepository()))
}
