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
    
    @State private var navigationPath: [String] = []
    
    var body: some View {
        VStack {
            NavigationStack(path: $navigationPath) {
                ScrollView {
                    if (deliveryViewModel.deliveries.count > 0) {
                        LazyVStack(alignment: .leading, spacing: 16) {
                            ForEach(groupDeliveriesByMonth(), id: \.key) { (monthYear, deliveries) in
                                VStack(alignment: (leftHanded ? .trailing : .leading), spacing: 8) {
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
                    } else {
                        VStack {
                            Spacer()
                            
                            Image(systemName: "figure.child")
                                .foregroundStyle(.indigo)
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Text("No deliveries recorded yet. Use the button above to get started!")
                                .multilineTextAlignment(.center)
                                .font(.title3)
                            
                            Spacer(minLength: 300)
                            
                            HStack {
                                Spacer()
                                
                                Image(systemName: "info.circle")
                                    .font(.title)
                                    .foregroundStyle(.indigo)
                                    .padding(.trailing)
                                
                                Text("You can submit up to 8 deliveries per day")
                                    .foregroundStyle(colorScheme == .dark ? Color.black : Color.white)
                                    .multilineTextAlignment(.center)
                                
                                Spacer()
                            }
                            .padding(8)
                            .background {
                                Rectangle()
                                    .foregroundStyle(colorScheme == .dark ? Color.white : Color.black)
                                    .cornerRadius(10)
                                    .shadow(radius: 5)
                            }
                        }
                        .padding()
                    }
                }
                .navigationTitle("Deliveries")
                .navigationDestination(for: Delivery.self) { delivery in
                    DeliveryDetailView(delivery: delivery)
                }
                .toolbar {
                    ToolbarItem {
                        Button(action: {
                            withAnimation {
                                showingDeliveryAddition = true
                            }
                        }, label: {
                            Text("New Delivery")
                                .bold()
                        })
                    }
                }
            }
        }
    }
    
    // TOOD: Post-release, let user delete their delivery entries
    
    private func groupDeliveriesByMonth() -> [(key: String, value: [Delivery])] {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM ''yy"
        
        var grouped: [String: [Delivery]] = [:]
        
        for delivery in deliveryViewModel.deliveries {
            let key = dateFormatter.string(from: delivery.date)
            if grouped[key] != nil {
                grouped[key]?.append(delivery)
            } else {
                grouped[key] = [delivery]
            }
        }
        
        let sortedKeys = grouped.keys.sorted { lhs, rhs in
            let lhsDate = dateFormatter.date(from: lhs) ?? Date.distantPast
            let rhsDate = dateFormatter.date(from: rhs) ?? Date.distantPast
            return lhsDate > rhsDate
        }
        
        return sortedKeys.map { key in (key, grouped[key] ?? []) }
    }
}

#Preview {
    DeliveryListView(showingDeliveryAddition: .constant(false))
        .environmentObject(DeliveryViewModel(deliveryRepository: MockDeliveryRepository()))
}
