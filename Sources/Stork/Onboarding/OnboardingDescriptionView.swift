//
//  OnboardingDescriptionTextView.swift
//
//
//  Created by Nick Molargik on 3/16/25.
//

import SwiftUI

struct OnboardingDescriptionView: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.body)
            .fontWeight(.semibold)
            .multilineTextAlignment(.center)
            .padding(.horizontal)
    }
}

#Preview {
    OnboardingDescriptionView(text: "Description")
}
