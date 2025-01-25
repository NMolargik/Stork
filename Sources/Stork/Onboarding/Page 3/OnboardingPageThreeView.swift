//
//  OnboardingPageThreeView.swift
//  skipapp-stork
//
//  Created by Nick Molargik on 1/22/25.
//

import SwiftUI

struct OnboardingPageThreeView: View {
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack {
            Text("Page 3")
                .font(.title)
                .fontWeight(.bold)
                .padding(.vertical)
        }
    }
}

#Preview {
    OnboardingPageThreeView()
}
