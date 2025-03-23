//
//  InfoBannerView.swift
//
//
//  Created by Nick Molargik on 3/17/25.
//

import SwiftUI

struct InfoBannerView: View {
    @Environment(\.colorScheme) var colorScheme
    
    @EnvironmentObject var appStorageManager: AppStorageManager

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
                .foregroundStyle(appStorageManager.useDarkMode ? Color.white : Color.black)

            Spacer()
        }
        .padding(8)
        .backgroundCard(colorScheme: colorScheme)
    }
}

#Preview {
    InfoBannerView(icon: "exclamationmark.triangle.fill", text: "info banner", color: Color.blue)
        .environmentObject(AppStorageManager())
}
