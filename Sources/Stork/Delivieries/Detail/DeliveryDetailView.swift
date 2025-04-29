//
//  DeliveryDetailView.swift
//
//  Created by Nick Molargik on 11/30/24.
//

import SwiftUI
import StorkModel

struct DeliveryDetailView: View {
    @AppStorage(StorageKeys.useDarkMode) var useDarkMode: Bool = false
    @AppStorage(StorageKeys.useMetric) var useMetric: Bool = false

    @Binding var delivery: Delivery

    var body: some View {
        VStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 15) {
                    Text(delivery.date.formatted(date: .omitted, time: .shortened))
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.leading)
                        .accessibilityLabel("Delivery Date: \(delivery.date.formatted(date: .omitted, time: .shortened))")
                        .foregroundStyle(useDarkMode ? Color.white : Color.black)

                    ForEach(delivery.babies, id: \.id) { baby in
                        BabyInfoCard(baby: baby, useMetric: useMetric)
                    }
                    
                    DeliveryDetailListView(delivery: delivery)
                    
                    HStack {
                        Text("ID: \(delivery.id)")
                            .foregroundStyle(.gray)
                            .font(.footnote)
                            .accessibilityLabel("Delivery ID: \(delivery.id)")
                        
                        Spacer()
                    }
                    .padding(.leading, 5)
                }
                .padding([.horizontal, .bottom])
            }
        }
        .navigationTitle(delivery.date.formatted(date: .long, time: .omitted))
        .onAppear { HapticFeedback.trigger(style: .medium) }
        .onDisappear { HapticFeedback.trigger(style: .medium) }
    }
}

#Preview {
    DeliveryDetailView(delivery: .constant(Delivery(sample: true)))
}
