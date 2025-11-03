//
//  SparkleText.swift
//  Stork
//
//  Created by Nick Molargik on 8/28/25.
//

import SwiftUI

struct SparkleText: View {
    var text: String
    @State private var phase: CGFloat = 0
    var body: some View {
        TimelineView(.animation) { timeline in
            let percent = CGFloat((timeline.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 1)) / 1)
            Text(text)
                .font(.title2)
                .bold()
                .foregroundStyle(.secondary)
                .overlay(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.clear, Color.white.opacity(0.7), Color.clear]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(height: 30)
                    .rotationEffect(.degrees(15))
                    .offset(x: percent * 350 - 200)
                    .blendMode(.plusLighter)
                    .mask(Text(text)
                            .font(.title2)
                            .bold())
                )
        }
        .padding()
    }
}

#Preview {
    SparkleText(text: "Sparkle Sparkle Sparkle")
}
