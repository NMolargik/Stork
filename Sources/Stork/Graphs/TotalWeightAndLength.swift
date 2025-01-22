//
//  TotalWeightAndLengthStatsView.swift
//  skipapp-stork
//
//  Created by Nick Molargik on 01/01/25.
//

import SwiftUI
import StorkModel

// MARK: - TotalWeightAndLength
/// A SwiftUI view that displays the total weight and length of all babies recorded over the last six months.
struct TotalWeightAndLengthStatsView: View {
    // MARK: - Properties
    
    /// Bindings to the grouped deliveries data, where each key is a month-year string and the value is an array of `Delivery` objects.
    @State var groupedDeliveries: [(key: String, value: [Delivery])]
    
    /// Whether to display the stats in metric units (kilograms and centimeters).
    @AppStorage("useMetric") private var useMetric: Bool = false
    
    // Total weight and length variables
    @State private var totalWeight: Double = 0.0 // In ounces by default
    @State private var totalLength: Double = 0.0 // In inches by default
    
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
                Text(weightString)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("&")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text(lengthString)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
            }
            .padding()
            
            Text("Delivered")
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
    
    // MARK: - Computed Properties
    
    /// A formatted string for the total weight.
    private var weightString: String {
        if useMetric {
            let totalWeightKg = (totalWeight / 16) * 0.453592
            return "\(Int(round(totalWeightKg))) kg"
        } else {
            let totalWeightLbs = totalWeight / 16
            return "\(Int(round(totalWeightLbs))) lbs"
        }
    }
    
    /// A formatted string for the total length.
    private var lengthString: String {
        if useMetric {
            let totalLengthCm = totalLength * 2.54
            return "\(Int(round(totalLengthCm))) cm"
        } else {
            return "\(Int(round(totalLength))) in"
        }
    }
    
    // MARK: - Helper Methods
    
    /// Calculates the total weight and length of babies from the grouped deliveries.
    private func calculateTotalStats() {
        var weightSum: Double = 0.0 // In ounces
        var lengthSum: Double = 0.0 // In inches
        
        for (_, deliveries) in groupedDeliveries {
            for delivery in deliveries {
                for baby in delivery.babies {
                    weightSum += baby.weight
                    lengthSum += baby.height
                }
            }
        }
        
        totalWeight = weightSum
        totalLength = lengthSum
    }
}

// MARK: - Preview
struct TotalWeightAndLengthStatsView_Previews: PreviewProvider {
    static var previews: some View {
        TotalWeightAndLengthStatsView(groupedDeliveries: [
            (key: "July '24", value: [
                Delivery(id: "1", userId: "U1", userFirstName: "Alice", hospitalId: "H1", hospitalName: "General Hospital", musterId: "M1", date: Date(), babies: [
                    Baby(deliveryId: "1", nurseCatch: true, sex: .male, weight: 120.0, height: 20.5), // 120 oz (7.5 lbs)
                    Baby(deliveryId: "1", nurseCatch: false, sex: .female, weight: 108.0, height: 19.8) // 108 oz (6.75 lbs)
                ], babyCount: 2, deliveryMethod: .vaginal, epiduralUsed: true)
            ]),
            (key: "August '24", value: [
                Delivery(id: "2", userId: "U2", userFirstName: "Bob", hospitalId: "H2", hospitalName: "City Hospital", musterId: "M2", date: Date(), babies: [
                    Baby(deliveryId: "2", nurseCatch: false, sex: .male, weight: 132.0, height: 21.2), // 132 oz (8.25 lbs)
                    Baby(deliveryId: "2", nurseCatch: true, sex: .loss, weight: 37.0, height: 14.7) // 37 oz (2.31 lbs)
                ], babyCount: 2, deliveryMethod: .cSection, epiduralUsed: false)
            ])
        ])
    }
}
