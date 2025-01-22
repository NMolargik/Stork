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
                Image(systemName: "figure.child")
                    .foregroundStyle(.purple)
                
                Image(systemName: "figure.child")
                    .foregroundStyle(.pink)
                    .shadow(radius: 2)

                Image(systemName: "figure.child")
                    .foregroundStyle(.blue)
                    .shadow(radius: 2)
            }
            .font(.largeTitle)
            .offset(x: -5)
            .frame(width: 50)

            Text("No deliveries recorded yet. Use the button above to get started!")
                .multilineTextAlignment(.center)
                .font(.title3)
                .fontWeight(.semibold)
                .padding(.top, 8)

            Spacer(minLength: 300)

            // MARK: - Info Banner
            InfoBannerView()
        }
        .padding()
    }
}

#Preview {
    EmptyStateView()
}
