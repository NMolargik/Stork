//
//  OnboardingCompletePage.swift
//  Stork
//
//  Created by Nick Molargik on 10/2/25.
//

import SwiftUI

struct OnboardingCompletePage: View {
    var onFinish: () -> Void

    @State private var showContent = false
    @State private var showButton = false

    private let features: [(icon: String, color: Color, title: String)] = [
        ("stethoscope", .storkPink, "Track your deliveries"),
        ("icloud.fill", .storkBlue, "Sync across devices"),
        ("chart.line.uptrend.xyaxis", .storkPurple, "View trends over time"),
        ("square.grid.3x3.fill", .storkOrange, "Fill your Delivery Jar")
    ]

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Header
            VStack(spacing: 16) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(.green)
                    .symbolEffect(.bounce, value: showContent)
                    .accessibilityHidden(true)

                Text("You're All Set!")
                    .font(.largeTitle.bold())

                Text("Here's what you can do with Stork")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
            .opacity(showContent ? 1 : 0)
            .offset(y: showContent ? 0 : 20)

            Spacer()

            // Features
            VStack(spacing: 0) {
                ForEach(Array(features.enumerated()), id: \.offset) { index, feature in
                    HStack(spacing: 14) {
                        Image(systemName: feature.icon)
                            .font(.title3)
                            .foregroundStyle(feature.color)
                            .frame(width: 28)

                        Text(feature.title)
                            .font(.body)

                        Spacer()

                        Image(systemName: "checkmark")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.green)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .opacity(showContent ? 1 : 0)
                    .offset(x: showContent ? 0 : (index.isMultiple(of: 2) ? -30 : 30))
                    .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(Double(index) * 0.1), value: showContent)

                    if index < features.count - 1 {
                        Divider().padding(.leading, 56)
                    }
                }
            }
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .frame(maxWidth: 500)
            .padding(.horizontal, 20)

            Spacer()

            // Enter Button
            Button {
                Haptics.mediumImpact()
                onFinish()
            } label: {
                HStack(spacing: 8) {
                    Text("Enter Stork")
                        .font(.headline)
                    Image(systemName: "arrow.right")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(Color.storkPurple)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(.plain)
            .frame(maxWidth: 500)
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
            .opacity(showButton ? 1 : 0)
            .offset(y: showButton ? 0 : 20)
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .task {
            try? await Task.sleep(nanoseconds: 300_000_000)
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                showContent = true
            }
            try? await Task.sleep(nanoseconds: 800_000_000)
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                showButton = true
            }
        }
    }
}

#Preview {
    OnboardingCompletePage(onFinish: {})
}
