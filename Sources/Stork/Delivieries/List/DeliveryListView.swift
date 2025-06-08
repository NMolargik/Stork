//
//  DeliveryListView.swift
//
//  Created by Nick Molargik on 11/30/24.
//

import SwiftUI
import StorkModel

struct DeliveryListView: View {
    @ObservedObject var deliveryViewModel: DeliveryViewModel
    @ObservedObject var profileViewModel: ProfileViewModel

    var body: some View {
        ZStack {
            List {
                // MARK: - Empty State
                if deliveryViewModel.deliveries.isEmpty {
                    EmptyStateView()
                        .listRowBackground(Color.clear)
                        #if !SKIP
                        .listRowInsets(.none)
                        #endif
                } else {
                    // MARK: - Sections for Each Month
                    ForEach(deliveryViewModel.groupedDeliveries, id: \.key) { (monthYear, deliveries) in
                        Section(header: SectionHeaderView(title: monthYear)) {
                            ForEach(deliveries, id: \.id) { delivery in
                                NavigationLink(value: delivery) {
                                    DeliveryRowView(delivery: delivery)
                                }
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.clear)
                            }
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    DeliveryListView(
        deliveryViewModel: DeliveryViewModel(deliveryRepository: MockDeliveryRepository()), 
        profileViewModel: ProfileViewModel(profileRepository: MockProfileRepository())
    )
}
