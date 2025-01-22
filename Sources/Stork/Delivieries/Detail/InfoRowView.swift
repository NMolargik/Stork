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
        HStack {
            icon
                .foregroundStyle(iconColor)
                .font(.title2)
                .frame(width: 30)
                .accessibilityHidden(true)

            Text(text)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.black)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .accessibilityLabel(text)
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 20).fill(Color.white).shadow(radius: 2).opacity(0.9))
        .padding(.horizontal)
    }
}

#Preview {
    InfoRowView(icon: Image(systemName: "info"), text: "Info", iconColor: Color.blue)
}
