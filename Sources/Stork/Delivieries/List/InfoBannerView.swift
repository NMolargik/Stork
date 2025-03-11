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
            Image("exclamationmark.circle")
                .resizable()
                .scaledToFit()
                .frame(width: 24, height: 24)                .foregroundStyle(Color("storkBlue"))
                .padding(.trailing)

            Text("You can submit up to 8 deliveries per day")
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
    InfoBannerView()
}
