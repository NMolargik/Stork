//
//  AnimatedStatViews.swift
//  StorkDesignSystem
//
//  Reusable counting/animating stat displays used across the dashboard cards.
//

import SwiftUI

// MARK: - Animated Number

/// Animates number changes with a counting effect.
public struct AnimatedNumber: View {
    private let value: Double
    private let format: String
    private let font: Font
    private let fontWeight: Font.Weight
    private let color: Color

    @State private var displayedValue: Double = 0
    @State private var hasAppeared = false

    public init(
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

    public var body: some View {
        Text(String(format: format, displayedValue))
            .font(font)
            .fontWeight(fontWeight)
            .foregroundStyle(color)
            .contentTransition(.numericText(value: displayedValue))
            .accessibilityLabel(String(format: format, value))
            .onAppear {
                guard !hasAppeared else { return }
                hasAppeared = true
                withAnimation(.spring(duration: 0.8, bounce: 0.2)) { displayedValue = value }
            }
            .onChange(of: value) { _, newValue in
                withAnimation(.spring(duration: 0.6, bounce: 0.15)) { displayedValue = newValue }
            }
    }
}

// MARK: - Animated Percentage

/// Animates a percentage with a trailing "%".
public struct AnimatedPercentage: View {
    private let value: Double
    private let font: Font
    private let fontWeight: Font.Weight
    private let color: Color

    @State private var displayedValue: Double = 0
    @State private var hasAppeared = false

    public init(
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

    public var body: some View {
        HStack(spacing: 0) {
            Text(String(format: "%.1f", displayedValue))
                .contentTransition(.numericText(value: displayedValue))
            Text("%")
        }
        .font(font)
        .fontWeight(fontWeight)
        .foregroundStyle(color)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(String(format: "%.1f percent", value))
        .onAppear {
            guard !hasAppeared else { return }
            hasAppeared = true
            withAnimation(.spring(duration: 0.8, bounce: 0.2)) { displayedValue = value }
        }
        .onChange(of: value) { _, newValue in
            withAnimation(.spring(duration: 0.6, bounce: 0.15)) { displayedValue = newValue }
        }
    }
}

// MARK: - Animated Progress Bar

/// Animates a segmented horizontal progress bar.
public struct AnimatedProgressBar: View {
    public struct Segment: Identifiable {
        public let id = UUID()
        public let value: Double
        public let color: Color
        public init(value: Double, color: Color) {
            self.value = value
            self.color = color
        }
    }

    private let segments: [Segment]
    private let height: CGFloat

    @State private var displayedSegments: [Double] = []
    @State private var hasAppeared = false

    public init(segments: [Segment], height: CGFloat = 14) {
        self.segments = segments
        self.height = height
    }

    public var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            ZStack {
                Capsule().fill(.ultraThinMaterial)

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

                Capsule().strokeBorder(.white.opacity(0.12))
            }
        }
        .frame(height: height + 2)
        .accessibilityHidden(true)
        .onAppear {
            guard !hasAppeared else { return }
            hasAppeared = true
            displayedSegments = segments.map { _ in 0 }
            withAnimation(.spring(duration: 1.0, bounce: 0.2)) {
                displayedSegments = segments.map { $0.value }
            }
        }
        .onChange(of: segments.map { $0.value }) { _, newValues in
            withAnimation(.spring(duration: 0.6, bounce: 0.15)) { displayedSegments = newValues }
        }
    }
}

// MARK: - Animated Stat Text

/// Animates a value with a textual suffix, e.g. "1.4 babies / delivery".
public struct AnimatedStatText: View {
    private let value: Double
    private let format: String
    private let suffix: String
    private let font: Font
    private let fontWeight: Font.Weight

    @State private var displayedValue: Double = 0
    @State private var hasAppeared = false

    public init(
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

    public var body: some View {
        HStack(spacing: 4) {
            Text(String(format: format, displayedValue))
                .contentTransition(.numericText(value: displayedValue))
            Text(suffix)
        }
        .font(font)
        .fontWeight(fontWeight)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(String(format: format, value)) \(suffix)")
        .onAppear {
            guard !hasAppeared else { return }
            hasAppeared = true
            withAnimation(.spring(duration: 0.8, bounce: 0.2)) { displayedValue = value }
        }
        .onChange(of: value) { _, newValue in
            withAnimation(.spring(duration: 0.6, bounce: 0.15)) { displayedValue = newValue }
        }
    }
}

// MARK: - Animated Integer

/// Animates integer changes (deliveries, babies count).
public struct AnimatedInteger: View {
    private let value: Int
    private let font: Font
    private let fontWeight: Font.Weight
    private let color: Color

    @State private var displayedValue: Int = 0
    @State private var hasAppeared = false

    public init(
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

    public var body: some View {
        Text("\(displayedValue)")
            .font(font)
            .fontWeight(fontWeight)
            .foregroundStyle(color)
            .contentTransition(.numericText(value: Double(displayedValue)))
            .accessibilityLabel("\(value)")
            .onAppear {
                guard !hasAppeared else { return }
                hasAppeared = true
                withAnimation(.spring(duration: 0.8, bounce: 0.2)) { displayedValue = value }
            }
            .onChange(of: value) { _, newValue in
                withAnimation(.spring(duration: 0.6, bounce: 0.15)) { displayedValue = newValue }
            }
    }
}

#if DEBUG
#Preview("Animated Number") { AnimatedNumber(value: 42.5, format: "%.1f") }

#Preview("Animated Percentage") { AnimatedPercentage(value: 73.5) }

#Preview("Animated Progress Bar") {
    AnimatedProgressBar(segments: [
        .init(value: 45, color: .blue),
        .init(value: 35, color: .orange),
        .init(value: 20, color: .purple),
    ])
    .padding()
}
#endif
