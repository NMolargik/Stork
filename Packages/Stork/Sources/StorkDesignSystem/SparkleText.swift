//
//  SparkleText.swift
//  StorkDesignSystem
//
//  An animated shimmering title, used for celebratory moments.
//

import SwiftUI

public struct SparkleText: View {
    private let text: String

    public init(text: String) {
        self.text = text
    }

    public var body: some View {
        TimelineView(.animation) { timeline in
            let percent = CGFloat(timeline.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 1))
            Text(text)
                .font(.title2)
                .bold()
                .foregroundStyle(.secondary)
                .overlay(
                    LinearGradient(
                        gradient: Gradient(colors: [.clear, .white.opacity(0.7), .clear]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(height: 30)
                    .rotationEffect(.degrees(15))
                    .offset(x: percent * 350 - 200)
                    .blendMode(.plusLighter)
                    .mask(Text(text).font(.title2).bold())
                )
        }
        .padding()
    }
}

#if DEBUG
#Preview {
    SparkleText(text: "Sparkle Sparkle Sparkle")
}
#endif
