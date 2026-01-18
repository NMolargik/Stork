//
//  MilestoneCardView.swift
//  Stork
//
//  Created by Nick Molargik on 1/17/26.
//

import SwiftUI

struct MilestoneCardView: View {
    let count: Int
    let milestoneType: CardImageRenderer.MilestoneType
    let userName: String?

    var body: some View {
        VStack(spacing: 20) {
            // Star icon
            Image(systemName: "star.fill")
                .font(.system(size: 50))
                .foregroundStyle(.yellow)
                .shadow(color: .yellow.opacity(0.5), radius: 10)

            // Prefix text
            Text(prefixText)
                .font(.title3)
                .foregroundStyle(.secondary)

            // Big number
            Text("\(count)")
                .font(.system(size: 72, weight: .bold, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.storkBlue, .storkPurple],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )

            // Suffix text
            Text(suffixText)
                .font(.title3)
                .foregroundStyle(.secondary)

            // User name if provided
            if let name = userName, !name.isEmpty {
                Text("— \(name)")
                    .font(.headline)
                    .foregroundStyle(.tertiary)
                    .padding(.top, 4)
            }

            // Branding
            Image("storkicon")
                .resizable()
                .scaledToFit()
                .frame(width: 28, height: 28)
                .padding(.top, 8)
        }
        .padding(40)
        .frame(width: 380, height: 480)
        .background(
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(uiColor: .systemBackground),
                            Color(uiColor: .secondarySystemBackground)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [.white.opacity(0.3), .clear],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )
        )
        .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 10)
    }

    private var prefixText: String {
        switch milestoneType {
        case .babies:
            return "I've delivered"
        case .deliveries:
            return "I've completed"
        }
    }

    private var suffixText: String {
        switch milestoneType {
        case .babies:
            return count == 1 ? "baby!" : "babies!"
        case .deliveries:
            return count == 1 ? "delivery!" : "deliveries!"
        }
    }
}

#Preview("500 Babies") {
    MilestoneCardView(
        count: 500,
        milestoneType: .babies,
        userName: "Sarah Johnson"
    )
}

#Preview("100 Deliveries") {
    MilestoneCardView(
        count: 100,
        milestoneType: .deliveries,
        userName: nil
    )
}
