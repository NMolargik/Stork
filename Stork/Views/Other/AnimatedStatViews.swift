//
//  AnimatedStatViews.swift
//  Stork
//
//  Created by Nick Molargik on 1/17/26.
//

import SwiftUI

// MARK: - Animated Number

/// A view that animates number changes with a counting effect
struct AnimatedNumber: View {
    let value: Double
    let format: String
    let font: Font
    let fontWeight: Font.Weight
    let color: Color

    @State private var displayedValue: Double = 0
    @State private var hasAppeared = false

    init(
        value: Double,
        format: String = "%.0f",
        font: Font = .title2,
        fontWeight: Font.Weight = .bold,
        color: Color = .primary
    ) {
        self.value = value
        self.format = format
        self.font = font
        self.fontWeight = fontWeight
        self.color = color
    }

    var body: some View {
        Text(String(format: format, displayedValue))
            .font(font)
            .fontWeight(fontWeight)
            .foregroundStyle(color)
            .contentTransition(.numericText(value: displayedValue))
            .onAppear {
                guard !hasAppeared else { return }
                hasAppeared = true
                withAnimation(.spring(duration: 0.8, bounce: 0.2)) {
                    displayedValue = value
                }
            }
            .onChange(of: value) { oldValue, newValue in
                withAnimation(.spring(duration: 0.6, bounce: 0.15)) {
                    displayedValue = newValue
                }
            }
    }
}

// MARK: - Animated Percentage

/// A view that animates percentage display with suffix
struct AnimatedPercentage: View {
    let value: Double
    let font: Font
    let fontWeight: Font.Weight
    let color: Color

    @State private var displayedValue: Double = 0
    @State private var hasAppeared = false

    init(
        value: Double,
        font: Font = .title2,
        fontWeight: Font.Weight = .bold,
        color: Color = .primary
    ) {
        self.value = value
        self.font = font
        self.fontWeight = fontWeight
        self.color = color
    }

    var body: some View {
        HStack(spacing: 0) {
            Text(String(format: "%.1f", displayedValue))
                .contentTransition(.numericText(value: displayedValue))
            Text("%")
        }
        .font(font)
        .fontWeight(fontWeight)
        .foregroundStyle(color)
        .onAppear {
            guard !hasAppeared else { return }
            hasAppeared = true
            withAnimation(.spring(duration: 0.8, bounce: 0.2)) {
                displayedValue = value
            }
        }
        .onChange(of: value) { oldValue, newValue in
            withAnimation(.spring(duration: 0.6, bounce: 0.15)) {
                displayedValue = newValue
            }
        }
    }
}

// MARK: - Animated Progress Bar

/// A view that animates a horizontal progress bar
struct AnimatedProgressBar: View {
    let segments: [Segment]
    let height: CGFloat

    struct Segment: Identifiable {
        let id = UUID()
        let value: Double
        let color: Color
    }

    @State private var displayedSegments: [Double] = []
    @State private var hasAppeared = false

    init(segments: [Segment], height: CGFloat = 14) {
        self.segments = segments
        self.height = height
    }

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            ZStack {
                Capsule()
                    .fill(.ultraThinMaterial)

                HStack(spacing: 0) {
                    ForEach(Array(zip(segments.indices, segments)), id: \.1.id) { index, segment in
                        let displayValue = index < displayedSegments.count ? displayedSegments[index] : 0
                        Rectangle()
                            .fill(segment.color)
                            .frame(width: w * CGFloat(displayValue / 100.0))
                    }
                }
                .frame(height: height)
                .clipShape(Capsule())

                Capsule()
                    .strokeBorder(.white.opacity(0.12))
            }
        }
        .frame(height: height + 2)
        .onAppear {
            guard !hasAppeared else { return }
            hasAppeared = true
            displayedSegments = segments.map { _ in 0 }
            withAnimation(.spring(duration: 1.0, bounce: 0.2)) {
                displayedSegments = segments.map { $0.value }
            }
        }
        .onChange(of: segments.map { $0.value }) { oldValues, newValues in
            withAnimation(.spring(duration: 0.6, bounce: 0.15)) {
                displayedSegments = newValues
            }
        }
    }
}

// MARK: - Animated Stat Text

/// A view that animates text changes like "X babies / delivery"
struct AnimatedStatText: View {
    let value: Double
    let format: String
    let suffix: String
    let font: Font
    let fontWeight: Font.Weight

    @State private var displayedValue: Double = 0
    @State private var hasAppeared = false

    init(
        value: Double,
        format: String = "%.1f",
        suffix: String,
        font: Font = .title3,
        fontWeight: Font.Weight = .semibold
    ) {
        self.value = value
        self.format = format
        self.suffix = suffix
        self.font = font
        self.fontWeight = fontWeight
    }

    var body: some View {
        HStack(spacing: 4) {
            Text(String(format: format, displayedValue))
                .contentTransition(.numericText(value: displayedValue))
            Text(suffix)
        }
        .font(font)
        .fontWeight(fontWeight)
        .onAppear {
            guard !hasAppeared else { return }
            hasAppeared = true
            withAnimation(.spring(duration: 0.8, bounce: 0.2)) {
                displayedValue = value
            }
        }
        .onChange(of: value) { oldValue, newValue in
            withAnimation(.spring(duration: 0.6, bounce: 0.15)) {
                displayedValue = newValue
            }
        }
    }
}

// MARK: - Animated Integer

/// A view that animates integer changes (deliveries, babies count)
struct AnimatedInteger: View {
    let value: Int
    let font: Font
    let fontWeight: Font.Weight
    let color: Color

    @State private var displayedValue: Int = 0
    @State private var hasAppeared = false

    init(
        value: Int,
        font: Font = .body,
        fontWeight: Font.Weight = .regular,
        color: Color = .primary
    ) {
        self.value = value
        self.font = font
        self.fontWeight = fontWeight
        self.color = color
    }

    var body: some View {
        Text("\(displayedValue)")
            .font(font)
            .fontWeight(fontWeight)
            .foregroundStyle(color)
            .contentTransition(.numericText(value: Double(displayedValue)))
            .onAppear {
                guard !hasAppeared else { return }
                hasAppeared = true
                withAnimation(.spring(duration: 0.8, bounce: 0.2)) {
                    displayedValue = value
                }
            }
            .onChange(of: value) { oldValue, newValue in
                withAnimation(.spring(duration: 0.6, bounce: 0.15)) {
                    displayedValue = newValue
                }
            }
    }
}

// MARK: - Previews

#Preview("Animated Number") {
    AnimatedNumber(value: 42.5, format: "%.1f")
}

#Preview("Animated Percentage") {
    AnimatedPercentage(value: 73.5)
}

#Preview("Animated Progress Bar") {
    AnimatedProgressBar(segments: [
        .init(value: 45, color: .blue),
        .init(value: 35, color: .orange),
        .init(value: 20, color: .purple)
    ])
    .padding()
}
