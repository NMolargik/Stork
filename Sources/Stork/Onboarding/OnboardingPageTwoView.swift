//
//  OnboardingPageTwoView.swift
//  skipapp-stork
//
//  Created by Nick Molargik on 1/22/25.
//

import SwiftUI
import StorkModel

struct OnboardingPageTwoView: View {
    @State private var sampleBaby = Baby(deliveryId: "", nurseCatch: true, nicuStay: false, sex: .male)

    var body: some View {
        VStack(spacing: 16) {
            BabyEditorView(
                baby: $sampleBaby,
                babyNumber: 1,
                removeBaby: { _ in },
                sampleMode: true
            )
            .padding()

            OnboardingDescriptionView(
                text: "Add deliveries simply by adding babies and filling out a few additional options.\n\nYour deliveries are all backed up and detailed history is available."
            )
            .padding()
        }
    }
}

#Preview {
    OnboardingPageTwoView()
}
