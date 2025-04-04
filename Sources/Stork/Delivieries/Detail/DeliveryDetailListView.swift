//
//  DeliveryDetailListView.swift
//  skipapp-stork
//
//  Created by Nick Molargik on 1/22/25.
//

import SwiftUI
import StorkModel

struct DeliveryDetailListView: View {
    @AppStorage(StorageKeys.useDarkMode) var useDarkMode: Bool = false
    
    let delivery: Delivery

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 10) {
                InfoRowView(
                    icon: Image("building.fill", bundle: .module),
                    text: delivery.hospitalName,
                    iconColor: Color("storkOrange")
                )
                
                if delivery.epiduralUsed {
                    InfoRowView(
                        icon: Image("syringe.fill", bundle: .module),
                        text: "Epidural Used",
                        iconColor: Color.green
                    )
                }
                
                InfoRowView(
                    icon: Image("shippingbox.fill", bundle: .module),
                    text: "\(delivery.deliveryMethod.description) Delivery",
                    iconColor: Color("storkIndigo")
                )
                
                if !delivery.musterId.isEmpty {
                    InfoRowView(
                        icon: Image("person.3.fill", bundle: .module),
                        text: "Added to your muster",
                        iconColor: Color.red
                    )
                }
            }
            
            Spacer()

        }
        .frame(maxWidth: .infinity)
        .padding()
        .backgroundCard(colorScheme: useDarkMode ? .dark : .light)
    }
}
#Preview {
    DeliveryDetailListView(delivery: Delivery(sample: true))
}
