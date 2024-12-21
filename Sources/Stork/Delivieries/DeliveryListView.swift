//
//  DeliveryListView.swift
//
//
//  Created by Nick Molargik on 11/30/24.
//

import SwiftUI
import StorkModel

struct DeliveryListView: View {
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("leftHanded") var leftHanded: Bool = false
    @EnvironmentObject var deliveryViewModel: DeliveryViewModel
    
    @Binding var showingDeliveryAddition: Bool
    
    var body: some View {
        // If you prefer a scrollable list style, wrap your ForEach in a List:
        List {
            let grouped = groupDeliveriesByMonth()
            
            if deliveryViewModel.deliveries.isEmpty {
                emptyStateView
            } else {
                ForEach(grouped, id: \.key) { (monthYear, deliveries) in
                    Section(header:
                        Text(monthYear)
                            .font(.title)
                            .foregroundStyle(.primary)
                            .fontWeight(.bold)
                            .opacity(0.2)
                    ) {
                        if deliveries.isEmpty {
                            Text("No deliveries found")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        } else {
                            ForEach(deliveries, id: \.id) { delivery in
                                NavigationLink(value: delivery) {
                                    DeliveryRowView(delivery: delivery)
                                        .padding(.vertical, 4)
                                    
                                }
                                .listRowSeparator(.hidden)
                            }
                        }
                    }
                }
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack {
            Spacer()
            Image(systemName: "figure.child")
                .foregroundStyle(.indigo)
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.bottom, 30)
            
            Text("No deliveries recorded yet. Use the button above to get started!")
                .multilineTextAlignment(.center)
                .font(.title3)
                .fontWeight(.semibold)
            
            Spacer(minLength: 300)
            
            HStack {
                Spacer()
                Image(systemName: "exclamationmark.circle")
                    .font(.title)
                    .foregroundStyle(.blue)
                    .padding(.trailing)
                    .foregroundStyle(.orange)
                
                Text("You can submit up to 8 deliveries per day")
                    .foregroundStyle(.black)
                    .multilineTextAlignment(.center)
                
                Spacer()
            }
            .padding(8)
            .background {
                Rectangle()
                    .foregroundStyle(.white)
                    .cornerRadius(10)
                    .shadow(radius: 2)
            }
        }
        .padding()
    }
    
    private func groupDeliveriesByMonth() -> [(key: String, value: [Delivery])] {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM ''yy"
        
        var grouped: [String: [Delivery]] = [:]
        
        for delivery in deliveryViewModel.deliveries {
            let key = dateFormatter.string(from: delivery.date)
            grouped[key, default: []].append(delivery)
        }
        
        // Sort descending by date
        let sortedKeys = grouped.keys.sorted { lhs, rhs in
            let lhsDate = dateFormatter.date(from: lhs) ?? Date.distantPast
            let rhsDate = dateFormatter.date(from: rhs) ?? Date.distantPast
            return lhsDate < rhsDate
        }
        
        return sortedKeys.map { (key: $0, value: grouped[$0] ?? []) }
    }
}

#Preview {
    DeliveryListView(showingDeliveryAddition: .constant(false))
        .environmentObject(DeliveryViewModel(deliveryRepository: MockDeliveryRepository()))
}
