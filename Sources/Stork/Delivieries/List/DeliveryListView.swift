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
            
            if deliveryViewModel.hasMorePages {
                VStack {
                    Spacer()
                    
                    HStack {
                        Spacer()
                        if (deliveryViewModel.isWorking) {
                            ProgressView()
                                .frame(height: 50)
                                .tint(.indigo)
                        } else {
                            CustomButtonView(text: "Load More", width: 200, height: 50, color: Color.indigo, isEnabled: true, onTapAction: {
                                loadMoreDeliveries()
                            })
                        }
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: 60)
                    .padding(.vertical)
                }
            }
        }
    }

    // MARK: - Load More Deliveries
    private func loadMoreDeliveries() {
        Task {
            do {
                try await deliveryViewModel.fetchNextDeliveries(profile: profileViewModel.profile)
            } catch {
                print("Error loading more deliveries: \(error.localizedDescription)")
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
