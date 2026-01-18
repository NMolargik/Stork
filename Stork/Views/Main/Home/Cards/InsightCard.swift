//
//  InsightCard.swift
//  Stork
//
//  Created by Nick Molargik on 11/3/25.
//

import SwiftUI

struct InsightCard<Content: View>: View {
    let title: String
    let systemImage: String?
    let accent: Color
    let content: Content

    init(title: String, systemImage: String? = nil, accent: Color = .storkBlue, @ViewBuilder content: () -> Content) {
        self.title = title
        self.systemImage = systemImage
        self.accent = accent
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                if let systemImage {
                    Label(title, systemImage: systemImage)
                        .font(.headline.weight(.semibold))
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(accent, .primary)
                } else {
                    Text(title)
                        .font(.headline.weight(.semibold))
                }
                Spacer()
            }
            content
        }
        .padding(14)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(.ultraThinMaterial)
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(
                        LinearGradient(colors: [accent.opacity(0.14), .clear], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(.white.opacity(0.08))
        )
        .shadow(color: .black.opacity(0.08), radius: 10, x: 0, y: 4)
        .clipped()
        .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .hoverEffect(.lift)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(title) statistics")
    }
}

#Preview {
    InsightCard(title: "Title", content: {})
}
