//
//  OnboardingPageThreeView.swift
//  skipapp-stork
//
//  Created by Nick Molargik on 1/22/25.
//

import SwiftUI
import StorkModel

struct OnboardingPageThreeView: View {
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack {
            BabyEditorView(
                baby: .constant(Baby(deliveryId: "", nurseCatch: true, nicuStay: false, sex: .male)),
                babyNumber: 1,
                removeBaby: { _ in },
                sampleMode: true
            )
            .padding()
            
            Text("Add deliveries simply by adding babies and filling out a few additional options.\n\nYour deliveries are all backed up and detailed history is available.")
                .padding()
                .fontWeight(.semibold)
        }
    }
}

#Preview {
    OnboardingPageThreeView()
}
