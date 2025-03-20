//
//  InfoBannerView.swift
//
//
//  Created by Nick Molargik on 3/17/25.
//

import SwiftUI

struct InfoBannerView: View {
    @Environment(\.colorScheme) var colorScheme

    let icon: String
    let text: String
    let color: Color

    var body: some View {
        HStack {
            Spacer()

            Image(systemName: icon)
                .resizable()
                .scaledToFit()
                .frame(width: 24, height: 24)
                .foregroundStyle(color)
                .padding(.trailing)

            Text(text)
                .font(.title3)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)

            Spacer()
        }
        .padding(8)
        .backgroundCard(colorScheme: colorScheme)
    }
}

#Preview {
    InfoBannerView(icon: "exclamationmark.triangle.fill", text: "info banner", color: Color.blue)
}
