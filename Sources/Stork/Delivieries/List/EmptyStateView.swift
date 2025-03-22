//
//  EmptyStateView.swift
//  skipapp-stork
//
//  Created by Nick Molargik on 1/22/25.
//

import SwiftUI

struct EmptyStateView: View {
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack {
            Spacer()

            HStack(spacing: 16) {
                ForEach(["storkPurple", "storkPink", "storkBlue"], id: \.self) { color in
                    Image("figure.child")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 50, height: 50)
                        .foregroundStyle(Color(color))
                        .shadow(radius: 2)
                }
            }
            .font(.largeTitle)
            .offset(x: -5)
            .padding(.bottom)

            Text("No deliveries recorded yet. Use the button above to get started!")
                .padding()
                .multilineTextAlignment(.center)
                .font(.title3)
                .fontWeight(.semibold)
                .backgroundCard(colorScheme: colorScheme)

            Spacer(minLength: 200)

            InfoBannerView(
                icon: "exclamationmark.circle",
                text: "You can submit up to 8 deliveries per day",
                color: Color("storkBlue")
            )
        }
        .padding()
    }
}



#Preview {
    EmptyStateView()
}
