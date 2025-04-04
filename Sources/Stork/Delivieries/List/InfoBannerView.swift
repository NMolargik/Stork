//
//  InfoBannerView.swift
//
//
//  Created by Nick Molargik on 3/17/25.
//

import SwiftUI

struct InfoBannerView: View {
    @AppStorage(StorageKeys.useDarkMode) var useDarkMode: Bool = false
    
    let icon: String
    let text: String
    let color: Color

    var body: some View {
        HStack {
            Spacer()

            Image(icon, bundle: .module)
                .resizable()
                .scaledToFit()
                .frame(width: 24, height: 24)
                .foregroundStyle(color)
                .padding(.trailing)

            Text(text)
                .font(.body)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
                .foregroundStyle(useDarkMode ? Color.white : Color.black)

            Spacer()
        }
        .padding(8)
        .backgroundCard(colorScheme: useDarkMode ? .dark : .light)
    }
}

#Preview {
    InfoBannerView(icon: "exclamationmark.triangle.fill", text: "info banner", color: Color.blue)
}
