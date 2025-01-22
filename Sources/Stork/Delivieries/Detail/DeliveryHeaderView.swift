//
//  DeliveryHeaderView.swift
//  skipapp-stork
//
//  Created by Nick Molargik on 1/22/25.
//

import SwiftUI
import StorkModel

struct DeliveryHeaderView: View {
    let delivery: Delivery

    var body: some View {
        Text(delivery.date.formatted(date: .omitted, time: .shortened))
            .font(.title2)
            .fontWeight(.bold)
            .padding(.leading)
            .accessibilityLabel("Delivery Date: \(delivery.date.formatted(date: .omitted, time: .shortened))")
    }
}

#Preview {
    DeliveryHeaderView(delivery: Delivery(sample: true))
}
