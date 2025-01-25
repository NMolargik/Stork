//
//  DetailsView.swift
//  skipapp-stork
//
//  Created by Nick Molargik on 1/22/25.
//

import SwiftUI
import StorkModel

struct DetailsView: View {
    @Environment(\.colorScheme) var colorScheme
    let delivery: Delivery

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 10) {
                InfoRowView(
                    icon: Image(systemName: "building.fill"),
                    text: delivery.hospitalName,
                    iconColor: Color.orange
                )
                
                if delivery.epiduralUsed {
                    InfoRowView(
                        icon: Image(systemName: "syringe.fill"),
                        text: "Epidural Used",
                        iconColor: Color.green
                    )
                }
                
                InfoRowView(
                    icon: Image(systemName: "shippingbox.fill"),
                    text: "\(delivery.deliveryMethod.description) Delivery",
                    iconColor: Color.indigo
                )
                
                if !delivery.musterId.isEmpty {
                    InfoRowView(
                        icon: Image(systemName: "person.3.fill"),
                        text: "Added to your muster",
                        iconColor: Color.red
                    )
                }
            }
            
            Spacer()

        }
        .frame(maxWidth: .infinity)
        .padding()
        .backgroundCard(colorScheme: colorScheme)
        .padding(.horizontal)
    }
}
#Preview {
    DetailsView(delivery: Delivery(sample: true))
}
