//
//  InfoRowView.swift
//  skipapp-stork
//
//  Created by Nick Molargik on 1/22/25.
//

import SwiftUI

struct InfoRowView: View {
    @EnvironmentObject var appStorageManager: AppStorageManager
    
    let icon: Image
    let text: String
    let iconColor: Color

    var body: some View {
        HStack(spacing: 10) {
            icon
                .resizable()
                .scaledToFit()
                .frame(width: 30, height: 24)
                .foregroundStyle(iconColor)

            Text(text)
                .foregroundStyle(appStorageManager.useDarkMode ? Color.white : Color.black)
                .font(.subheadline)
                .fontWeight(.semibold)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .accessibilityLabel(text)
                .frame(minWidth: 50)
        }
    }
}

#Preview {
    InfoRowView(icon: Image("info", bundle: .module), text: "Info", iconColor: Color("storkBlue"))
        .environmentObject(AppStorageManager())
}
