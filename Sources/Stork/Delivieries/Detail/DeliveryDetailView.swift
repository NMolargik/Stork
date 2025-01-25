//
//  DeliveryDetailView.swift
//
//  Created by Nick Molargik on 11/30/24.
//

import SwiftUI
import StorkModel

struct DeliveryDetailView: View {
    // MARK: - AppStorage
    @AppStorage("useMetric") private var useMetric: Bool = false

    // MARK: - Environment Objects
    @EnvironmentObject var musterViewModel: MusterViewModel

    // MARK: - Binding
    @Binding var delivery: Delivery

    var body: some View {
        VStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 15) {
                    DeliveryHeaderView(delivery: delivery)

                    // MARK: - Babies Information
                    ForEach(delivery.babies, id: \.id) { baby in
                        BabyInfoCard(baby: baby, useMetric: useMetric)
                    }
                    
                    DetailsView(delivery: delivery)
                }
                .padding([.horizontal, .bottom])
            }

            Spacer()

            // MARK: - Delivery ID
            HStack {
                Spacer()
                Text("ID: \(delivery.id)")
                    .foregroundStyle(.gray)
                    .font(.footnote)
                    .accessibilityLabel("Delivery ID: \(delivery.id)")
            }
            .padding([.trailing, .bottom])
        }
        .navigationTitle(delivery.date.formatted(date: .long, time: .omitted))
        .onAppear { triggerHaptic() }
        .onDisappear { triggerHaptic() }
    }
}

// MARK: - Preview
struct DeliveryDetailView_Previews: PreviewProvider {
    static var previews: some View {
        DeliveryDetailView(delivery: .constant(Delivery(sample: true)))
            .environmentObject(MusterViewModel(musterRepository: MockMusterRepository()))
    }
}
