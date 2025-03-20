//
//  OnboardingPageThreeView.swift
//  skipapp-stork
//
//  Created by Nick Molargik on 1/22/25.
//

import SwiftUI
import StorkModel

struct OnboardingPageThreeView: View {
    var body: some View {
        VStack(spacing: 16) {
            Text("Join Your Peers!")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding()

            JarView(
                deliveries: Binding.constant(nil),
                headerText: "Delivery Jar",
                isTestMode: true,
                isMusterTest: true
            )
            .padding()
            .frame(height: 300)

            OnboardingDescriptionView(
                text: "Create or join a muster to share delivery statistics and trends with a whole group of your peers. Good luck filling this jar every week!"
            )
            .padding()
        }
    }
}

#Preview {
    OnboardingPageThreeView()
}
