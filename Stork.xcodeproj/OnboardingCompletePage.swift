//
//  OnboardingCompletePage.swift
//  Stork
//
//  Created by Assistant on 10/2/25.
//

import SwiftUI

struct OnboardingCompletePage: View {
    var onFinish: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Text("You're all set!")
                .font(.largeTitle).bold()
            Text("Thanks for setting things up. You can change permissions anytime in Settings.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
            Spacer()
            Button(action: onFinish) {
                Text("Enter Mygra")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .padding()
        }
    }
}

#Preview {
    NavigationStack {
        OnboardingCompletePage(onFinish: {})
    }
}
