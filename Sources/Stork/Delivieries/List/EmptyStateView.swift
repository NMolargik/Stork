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

            // MARK: - Animated Icon
            HStack(spacing: 16) {
                Image("figure.child")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 50, height: 50)
                    .foregroundStyle(Color("storkPurple"))
                    .shadow(radius: 2)

                
                Image("figure.child")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 50, height: 50)
                    .foregroundStyle(Color("storkPink"))
                    .shadow(radius: 2)

                Image("figure.child")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 50, height: 50)
                    .foregroundStyle(Color("storkBlue"))
                    .shadow(radius: 2)
            }
            .font(.largeTitle)
            .offset(x: -5)
            .frame(width: 50)
            .padding(.bottom)

            Text("No deliveries recorded yet. Use the button above to get started!")
                .padding()
                .multilineTextAlignment(.center)
                .font(.title3)
                .fontWeight(.semibold)
                .backgroundCard(colorScheme: colorScheme)

            Spacer(minLength: 200)

            InfoBannerView()
        }
        .padding()
    }
}

#Preview {
    EmptyStateView()
}
