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

    // MARK: - State to Hold a Stable Snapshot
    @State private var groupedDeliveriesSnapshot: [GroupedDeliveries] = []

    var body: some View {
        ZStack {
            List {
                // MARK: - Empty State
                if groupedDeliveriesSnapshot.isEmpty {
                    EmptyStateView()
                        .listRowBackground(Color.clear)
#if !SKIP
                        .listRowInsets(.none)
#endif
                } else {
                    // MARK: - Sections for Each Month
                    ForEach(Array(groupedDeliveriesSnapshot.enumerated()), id: \.element.key) { _, section in
                        Section(header: SectionHeader(title: section.key)) {
                            ForEach(section.deliveries, id: \.id) { delivery in
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
        .onAppear {
            groupedDeliveriesSnapshot = deliveryViewModel.groupedDeliveries
        }
        .onChange(of: deliveryViewModel.groupedDeliveries) { newValue in
            groupedDeliveriesSnapshot = newValue
        }
    }
}

// MARK: - Preview
#Preview {
    DeliveryListView(showingDeliveryAddition: .constant(false))
        .environmentObject(DeliveryViewModel(deliveryRepository: MockDeliveryRepository()))
        .environmentObject(ProfileViewModel(profileRepository: MockProfileRepository()))
}
