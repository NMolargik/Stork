//
//  DeliveryDetailView.swift
//
//
//  Created by Nick Molargik on 11/30/24.
//

import SwiftUI
import StorkModel

struct DeliveryDetailView: View {
    var delivery: Delivery
    
    //TODO: this

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {

            Text("Hospital ID: \(delivery.hospitalId)")
                .font(.subheadline)
            Text("Date: \(delivery.date.formatted(date: .long, time: .omitted))")
                .font(.subheadline)
            Text("Baby Count: \(delivery.babyCount)")
                .font(.subheadline)
            Text("Delivery Method: \(delivery.deliveryMethod.description)")
                .font(.subheadline)
            Text("Epidural Used: \(delivery.epiduralUsed ? "Yes" : "No")")
                .font(.subheadline)
            Spacer()
            
            HStack {
                Spacer()
                
                Text(delivery.id)
                    .font(.system(size: 6))
                    
            }
        }
        .padding()
        .navigationTitle("Delivery Details")
    }
}

#Preview {
    DeliveryDetailView(delivery: Delivery(sample: true))
}
