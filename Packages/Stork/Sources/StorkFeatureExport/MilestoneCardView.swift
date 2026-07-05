//
//  MilestoneCardView.swift
//  StorkFeatureExport
//
//  The shareable milestone card rendered to an image.
//

#if os(iOS)
import SwiftUI
import StorkDesignSystem

struct MilestoneCardView: View {
    let count: Int
    let milestoneType: CardImageRenderer.MilestoneType

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "star.fill")
                .font(.system(size: 50)).foregroundStyle(.yellow)
                .shadow(color: .yellow.opacity(0.5), radius: 10)
            Text(prefixText).font(.title3).foregroundStyle(.secondary)
            Text("\(count)")
                .font(.system(size: 72, weight: .bold, design: .rounded))
                .foregroundStyle(LinearGradient(colors: [.storkBlue, .storkPurple], startPoint: .leading, endPoint: .trailing))
            Text(suffixText).font(.title3).foregroundStyle(.secondary)
            Image("storkicon").resizable().scaledToFit().frame(width: 28, height: 28).padding(.top, 8)
        }
        .padding(40)
        .frame(width: 380, height: 480)
        .background(
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(LinearGradient(colors: [Color(uiColor: .systemBackground), Color(uiColor: .secondarySystemBackground)], startPoint: .top, endPoint: .bottom))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .strokeBorder(LinearGradient(colors: [.white.opacity(0.3), .clear], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 2)
        )
        .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 10)
    }

    private var prefixText: String {
        switch milestoneType {
        case .babies: "I've delivered"
        case .deliveries: "I've completed"
        }
    }

    private var suffixText: String {
        switch milestoneType {
        case .babies: count == 1 ? "baby!" : "babies!"
        case .deliveries: count == 1 ? "delivery!" : "deliveries!"
        }
    }
}
#endif
