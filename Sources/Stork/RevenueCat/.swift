//
//  PaymentInfoView.swift
//  skipapp-stork
//
//  Created by Nick Molargik on 1/13/25.
//

import SwiftUI

struct PaymentInfoView: View {
    var body: some View {
        VStack {
            Text("$5 per year helps keep Stork's services alive and responsive. We promise the feature set is more than worth it!")
                .font(.body)
                .multilineTextAlignment(.center)
                .padding()
        }
        .padding()
        .frame(width: 300)
        .cornerRadius(20)
    }
}
