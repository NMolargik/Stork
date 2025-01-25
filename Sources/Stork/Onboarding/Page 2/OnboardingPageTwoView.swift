//
//  OnboardingPageTwoView.swift
//  skipapp-stork
//
//  Created by Nick Molargik on 1/22/25.
//

import SwiftUI

struct OnboardingPageTwoView: View {
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack {
            Text("Page 2")
                .font(.title)
                .fontWeight(.bold)
                .padding(.vertical)
        }
    }
}

#Preview {
    OnboardingPageTwoView()
}
