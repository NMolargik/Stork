//
//  DeliveryListView.swift
//
//
//  Created by Nick Molargik on 11/30/24.
//

import SwiftUI
import StorkModel

struct DeliveryListView: View {
    @EnvironmentObject var deliveryViewModel: DeliveryViewModel
    @State private var navigationPath: [String] = []
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 16) {
                    // Group deliveries by month and year
                    ForEach(groupDeliveriesByMonth(), id: \.key) { (monthYear, deliveries) in
                        VStack(alignment: .leading, spacing: 8) {
                            // Month-Year Header
                            Text(monthYear)
                                .font(.largeTitle)
                                .foregroundStyle(.primary)
                                .fontWeight(.bold)
                                .opacity(0.2)
                                .padding(.leading, -15)
                            
                            if deliveries.isEmpty {
                                Text("No deliveries for \(monthYear).")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                    .padding(.leading)
                            } else {
                                ForEach(deliveries) { delivery in
                                    NavigationLink(destination: DeliveryDetailView(delivery: delivery)) {
                                        DeliveryRowView(delivery: delivery)
                                            .padding(.vertical, 4)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.top)
            }
            .navigationTitle("Deliveries")
            .navigationDestination(for: Delivery.self) { delivery in
                DeliveryDetailView(delivery: delivery)
            }
        }
    }
    
    // TOOD: Post release, let user delete their delivery entries
    
    
    /// Groups deliveries by month and year.
    private func groupDeliveriesByMonth() -> [(key: String, value: [Delivery])] {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM ''yy" // Format: Full month name and 2-digit year with apostrophe
        
        var grouped: [String: [Delivery]] = [:]
        
        // Manually group deliveries by month and year
        for delivery in deliveryViewModel.deliveries {
            let key = dateFormatter.string(from: delivery.date)
            if grouped[key] != nil {
                grouped[key]?.append(delivery)
            } else {
                grouped[key] = [delivery]
            }
        }
        
        // Sort keys by month and year descending
        let sortedKeys = grouped.keys.sorted { lhs, rhs in
            let lhsDate = dateFormatter.date(from: lhs) ?? Date.distantPast
            let rhsDate = dateFormatter.date(from: rhs) ?? Date.distantPast
            return lhsDate > rhsDate
        }
        
        // Return sorted groups
        return sortedKeys.map { key in (key, grouped[key] ?? []) }
    }
}

#Preview {
    DeliveryListView()
        .environmentObject(DeliveryViewModel(deliveryRepository: MockDeliveryRepository()))
}
