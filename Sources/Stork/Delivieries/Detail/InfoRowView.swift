//
//  InfoRowView.swift
//  skipapp-stork
//
//  Created by Nick Molargik on 1/22/25.
//

import SwiftUI

struct InfoRowView: View {
    let icon: Image
    let text: String
    let iconColor: Color

    var body: some View {
        HStack(spacing: 10) {
            icon
                .foregroundStyle(iconColor)
                .font(.title2)
                .frame(width: 40)
                .accessibilityHidden(true)

            Text(text)
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
    InfoRowView(icon: Image(systemName: "info"), text: "Info", iconColor: Color.blue)
}
