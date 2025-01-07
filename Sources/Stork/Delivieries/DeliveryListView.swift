//
//  DeliveryListView.swift
//
//  Created by Nick Molargik on 11/30/24.
//

import SwiftUI
import StorkModel

struct DeliveryListView: View {
    // MARK: - App Storage Variables
    @AppStorage("leftHanded") var leftHanded: Bool = false

    // MARK: - Environment Variables
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var deliveryViewModel: DeliveryViewModel
    
    // MARK: - Bindings
    @Binding var showingDeliveryAddition: Bool
    
    var body: some View {
        List {
            if deliveryViewModel.deliveries.isEmpty {
                emptyStateView
            } else {
                ForEach(deliveryViewModel.groupedDeliveries, id: \.key) { (monthYear, deliveries) in
                    Section(header:
                        Text(monthYear)
                            .font(.title)
                            .foregroundStyle(.primary)
                            .fontWeight(.bold)
                            .opacity(0.2)
                            .offset(x: -15)
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
            
            ZStack {
                Image(systemName: "figure.child")
                    .foregroundStyle(.purple)
                
                Image(systemName: "figure.child")
                    .foregroundStyle(.pink)
                    .shadow(radius: 2)
                    .offset(x: 16)

                Image(systemName: "figure.child")
                    .foregroundStyle(.blue)
                    .shadow(radius: 2)
                    .offset(x: 32)
            }
            .font(.largeTitle)
            .offset(x: -5)
            .frame(width: 30)
            
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
                
                Text("You can submit up to 8 deliveries per day")
                    .multilineTextAlignment(.center)
                
                Spacer()
            }
            .padding(8)
            .background {
                Rectangle()
                    .foregroundStyle(colorScheme == .dark ? .black : .white)
                    .cornerRadius(20)
                    .shadow(radius: 2)
            }
        }
        .padding()
    }
}

#Preview {
    DeliveryListView(showingDeliveryAddition: .constant(false))
        .environmentObject(DeliveryViewModel(deliveryRepository: MockDeliveryRepository()))
}
