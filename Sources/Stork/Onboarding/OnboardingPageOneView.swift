//
//  OnboardingPageOneView.swift
//  skipapp-stork
//
//  Created by Nick Molargik on 1/22/25.
//

import SwiftUI
import StorkModel

struct OnboardingPageOneView: View {
    var body: some View {
        VStack(spacing: 16) {
            Text("Welcome to Stork")
                .font(.title)
                .fontWeight(.bold)
                .padding(.vertical)

            HStack(spacing: 16) {
                JarView(
                    deliveries: Binding.constant(nil),
                    headerText: "Delivery Jar",
                    isTestMode: true,
                    isMusterTest: false
                )

                VStack(alignment: .leading, spacing: 8) {
                    ForEach(Sex.allCases) { sex in
                        OnboardingLegendItemView(color: sex.color, label: sex.description)
                    }
                }
                .frame(width: 120)
                .padding(.leading, 5)
                .fontWeight(.bold)

                Spacer()
            }
            .frame(height: 280)
            .padding(.horizontal)

            OnboardingDescriptionView(
                text: "Stork allows users to track trends in labor and delivery. This includes sex, weight, monthly totals, and more!\nYour delivery jar will fill up with colored marbles that each represent a baby delivered in the last week."
            )
        }
    }
}

#Preview {
    OnboardingPageOneView()
}
