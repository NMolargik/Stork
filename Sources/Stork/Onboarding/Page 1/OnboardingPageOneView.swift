//
//  OnboardingPageOneView.swift
//  skipapp-stork
//
//  Created by Nick Molargik on 1/22/25.
//

import SwiftUI

struct OnboardingPageOneView: View {
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack {
            Text("Welcome to Stork")
                .font(.title)
                .fontWeight(.bold)
                .padding(.vertical)

            HStack {
                JarView(deliveries: Binding.constant(nil), headerText: "Delivery Jar", isTestMode: true)
                
                LegendView()
                
                Spacer()
            }
            .frame(height: 280)
            .padding()

            Text("Stork allows users to track trends in labor and delivery. This includes sex, weight, monthly totals, and more!\n\nYour delivery jar will fill up with colored marbles that each represent a baby delivered in the last week.")
                .padding()
                .fontWeight(.semibold)
        }
    }
}

#Preview {
    OnboardingPageOneView()
}
