//
//  TotalDeliveryAndBabyStatsView.swift
//  skipapp-stork
//
//  Created by Nick Molargik on 01/01/25.
//

import SwiftUI
import StorkModel

// MARK: - TotalDeliveryAndBabyStatsView
/// A SwiftUI view that displays the total number of deliveries and babies over the last six months.
struct TotalDeliveryAndBabyStatsView: View {
    // MARK: - Properties
    
    /// Bindings to the grouped deliveries data, where each key is a month-year string and the value is an array of `Delivery` objects.
    @Binding var groupedDeliveries: [(key: String, value: [Delivery])]
    
    /// Total number of deliveries and babies.
    @State private var totalDeliveries: Int = 0
    @State private var totalBabies: Int = 0
    
    // MARK: - Body
    var body: some View {
        VStack {
            Spacer()
            
            Text("6 Month Stats")
                .fontWeight(.bold)
                .foregroundStyle(.gray)
                .offset(y: 25)
                .frame(height: 10)
                .padding(.bottom, 10)
            
            HStack(spacing: 10) {
                Text("\(totalDeliveries) Deliveries")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
                
                Text("&")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
                
                Text("\(totalBabies) Babies")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
            }
            .padding()
            
            Text("Recorded")
                .fontWeight(.bold)
                .foregroundStyle(.gray)
                .padding(.bottom, 10)
            
            Spacer()
        }
        .onAppear {
            calculateTotalStats()
        }
        .onChange(of: groupedDeliveries.count) { _ in
            calculateTotalStats()
        }
    }
    
    // MARK: - Helper Methods
    
    /// Calculates the total number of deliveries and babies from the grouped deliveries.
    private func calculateTotalStats() {
        var deliveryCount = 0
        var babyCount = 0
        
        for (_, deliveries) in groupedDeliveries {
            deliveryCount += deliveries.count
            for delivery in deliveries {
                babyCount += delivery.babies.count
            }
        }
        
        totalDeliveries = deliveryCount
        totalBabies = babyCount
    }
}

// MARK: - Preview
struct TotalDeliveryAndBabyStatsView_Previews: PreviewProvider {
    static var previews: some View {
        TotalDeliveryAndBabyStatsView(groupedDeliveries: .constant([
            (key: "July '24", value: [
                Delivery(id: "1", userId: "U1", userFirstName: "Alice", hospitalId: "H1", hospitalName: "General Hospital", musterId: "M1", date: Date(), babies: [
                    Baby(deliveryId: "1", nurseCatch: true, nicuStay: false, sex: .male, weight: 120.0, height: 20.5), // Baby 1
                    Baby(deliveryId: "1", nurseCatch: false, nicuStay: false, sex: .female, weight: 108.0, height: 19.8)  // Baby 2
                ], babyCount: 2, deliveryMethod: .vaginal, epiduralUsed: true)
            ]),
            (key: "August '24", value: [
                Delivery(id: "2", userId: "U2", userFirstName: "Bob", hospitalId: "H2", hospitalName: "City Hospital", musterId: "M2", date: Date(), babies: [
                    Baby(deliveryId: "2", nurseCatch: false, nicuStay: false, sex: .male, weight: 132.0, height: 21.2),  // Baby 3
                    Baby(deliveryId: "2", nurseCatch: true, nicuStay: false, sex: .loss, weight: 37.0, height: 14.7)      // Baby 4
                ], babyCount: 2, deliveryMethod: .cSection, epiduralUsed: false)
            ])
        ]))
    }
}
