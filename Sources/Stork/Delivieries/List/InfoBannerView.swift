//
//  InfoBannerView.swift
//  skipapp-stork
//
//  Created by Nick Molargik on 1/22/25.
//

import SwiftUI

struct InfoBannerView: View {
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        HStack {
            Spacer()
            Image(systemName: "exclamationmark.circle")
                .font(.title)
                .foregroundStyle(.blue)
                .padding(.trailing)

            Text("You can submit up to 8 deliveries per day")
                .multilineTextAlignment(.center)

            Spacer()
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(colorScheme == .dark ? Color.black : Color.white)
                .shadow(radius: 2)
        )
    }
}

#Preview {
    InfoBannerView()
}
