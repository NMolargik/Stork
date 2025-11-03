// DeliveryDetailBabyListView.swift
// Stork
//
// Created by Nick Molargik on 10/6/25.
//

import SwiftUI

struct DeliveryDetailBabyListView: View {
    let babies: [Baby]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if babies.isEmpty {
                Text("No babies recorded for this delivery.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
            } else {
                ForEach(babies.indices, id: \.self) { index in
                    BabyCardView(baby: babies[index], index: index + 1)
                        .padding(.horizontal)
                }
            }
        }
    }
}

#Preview {
    DeliveryDetailBabyListView(babies: Delivery.sample().babies ?? [])
}
