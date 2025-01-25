//
//  DeliveryListView.swift
//
//  Created by Nick Molargik on 11/30/24.
//

import SwiftUI
import StorkModel

struct DeliveryListView: View {
    // MARK: - Environment
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var deliveryViewModel: DeliveryViewModel
    @EnvironmentObject var profileViewModel: ProfileViewModel

    // MARK: - Binding
    @Binding var showingDeliveryAddition: Bool

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
                        Section(header: SectionHeader(title: monthYear)) {
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

// MARK: - Preview
#Preview {
    DeliveryListView(showingDeliveryAddition: .constant(false))
        .environmentObject(DeliveryViewModel(deliveryRepository: MockDeliveryRepository()))
        .environmentObject(ProfileViewModel(profileRepository: MockProfileRepository()))
}
