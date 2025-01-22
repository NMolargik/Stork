//
//  DetailsView.swift
//  skipapp-stork
//
//  Created by Nick Molargik on 1/22/25.
//

import SwiftUI
import StorkModel

struct DetailsView: View {
    let delivery: Delivery

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if delivery.epiduralUsed {
                InfoRowView(
                    icon: Image(systemName: "syringe.fill"),
                    text: "Epidural Used",
                    iconColor: .red
                )
            }

            InfoRowView(
                icon: Image(systemName: "shippingbox.fill"),
                text: "\(delivery.deliveryMethod.description) Delivery",
                iconColor: .indigo
            )

            if !delivery.musterId.isEmpty {
                InfoRowView(
                    icon: Image(systemName: "person.3.fill"),
                    text: "Added to your muster",
                    iconColor: .red
                )
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 20).fill(Color.white).shadow(radius: 2).opacity(0.9))
        .padding(.horizontal)
    }
}
#Preview {
    DetailsView(delivery: Delivery(sample: true))
}
