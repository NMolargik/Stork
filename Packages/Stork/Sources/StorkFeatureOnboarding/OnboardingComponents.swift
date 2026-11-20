//
//  OnboardingComponents.swift
//  StorkFeatureOnboarding
//
//  The page building blocks shared by every onboarding step, in the layout style of the other
//  Farside apps: the hero header (a tinted symbol tile, title, subtitle), the feature row and
//  card, and `OnboardingColumns`, which keeps content off an unfolded iPhone Duo's hinge.
//

#if os(iOS)
import SwiftUI
import StorkDesignSystem

// MARK: - Metrics

/// Spacing and widths shared by the onboarding screens and the splash.
enum OnboardingMetrics {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 24
    static let xxl: CGFloat = 32
    static let chipRadius: CGFloat = 10
    static let cardRadius: CGFloat = 18
    /// The width text and controls are capped at.
    static let readableWidth: CGFloat = 520
}

extension View {
    /// The card surface: material fill, hairline border, soft shadow.
    func onboardingCard() -> some View {
        let shape = RoundedRectangle(cornerRadius: OnboardingMetrics.cardRadius, style: .continuous)
        return self
            .background(.ultraThinMaterial, in: shape)
            .overlay(shape.strokeBorder(.quaternary))
            .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 4)
    }

    /// The prominent full-width button used for Continue / Get Started / Enter Stork.
    func onboardingPrimaryButton() -> some View {
        self
            .buttonStyle(.glassProminent)
            .controlSize(.large)
            .tint(.storkPurple)
    }
}

/// The platform's grouped background (onboarding pages).
var onboardingBackground: Color { Color(uiColor: .systemGroupedBackground) }

extension LayoutProbe {
    /// DEBUG only: `-StorkOnboardingFoldX <points>` pretends a vertical hinge sits at that x, so
    /// the unfolded-Duo columns can be checked on any simulator at a wide size.
    func withDebugFold() -> LayoutProbe {
        #if DEBUG
        if UserDefaults.standard.object(forKey: "StorkOnboardingFoldX") != nil, width > 0 {
            let x = UserDefaults.standard.double(forKey: "StorkOnboardingFoldX")
            var copy = self
            copy.hasFold = true
            copy.foldCenterX = CGFloat(x)
            return copy
        }
        #endif
        return self
    }
}

// MARK: - Header

/// Hero symbol on a tinted tile, then the title and subtitle.
struct OnboardingHeader: View {
    let systemImage: String
    let tint: Color
    let title: String
    let subtitle: String
    /// The tighter hero for short windows (the folded iPhone Duo, iPhone landscape).
    var compact = false
    /// Dropped on the shortest windows so the scrolling body gets the room.
    var showsSymbol = true

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var bounce = false

    @ScaledMetric(relativeTo: .largeTitle) private var symbolSize: CGFloat = 48
    @ScaledMetric(relativeTo: .largeTitle) private var symbolBox: CGFloat = 96
    @ScaledMetric(relativeTo: .largeTitle) private var compactSymbolSize: CGFloat = 32
    @ScaledMetric(relativeTo: .largeTitle) private var compactSymbolBox: CGFloat = 56

    var body: some View {
        let box = compact ? compactSymbolBox : symbolBox
        VStack(spacing: compact ? OnboardingMetrics.sm : OnboardingMetrics.lg) {
            if showsSymbol {
            Image(systemName: systemImage)
                .font(.system(size: compact ? compactSymbolSize : symbolSize, weight: .medium))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(tint)
                .contentTransition(.symbolEffect(.replace))
                .symbolEffect(.bounce, options: .nonRepeating, value: bounce)
                .frame(width: box, height: box)
                .background(RoundedRectangle(cornerRadius: box * 0.26, style: .continuous).fill(tint.opacity(0.18)))
                .overlay(RoundedRectangle(cornerRadius: box * 0.26, style: .continuous).strokeBorder(.quaternary))
                .accessibilityHidden(true)
            }

            VStack(spacing: compact ? OnboardingMetrics.xs : OnboardingMetrics.sm) {
                Text(title)
                    .font(.system(.title, design: .rounded, weight: .bold))
                    .multilineTextAlignment(.center)
                    .accessibilityAddTraits(.isHeader)
                Text(subtitle)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .accessibilityElement(children: .combine)
        }
        .frame(maxWidth: .infinity)
        .onAppear {
            guard !reduceMotion else { return }
            bounce.toggle()
        }
    }
}

// MARK: - Feature row

/// A tinted glyph, a title and an optional one-line detail. One accessibility element.
struct OnboardingFeatureRow: View {
    let icon: String
    let tint: Color
    let title: String
    var detail: String?
    var compact = false

    @ScaledMetric(relativeTo: .body) private var glyphBox: CGFloat = 36

    var body: some View {
        HStack(alignment: .center, spacing: OnboardingMetrics.md) {
            Image(systemName: icon)
                .font(.body.weight(.semibold))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(tint)
                .frame(width: glyphBox, height: glyphBox)
                .background(RoundedRectangle(cornerRadius: OnboardingMetrics.chipRadius, style: .continuous).fill(tint.opacity(0.18)))
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.body.weight(.semibold))
                if let detail {
                    Text(detail)
                        .font(compact ? .footnote : .subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Spacer(minLength: OnboardingMetrics.sm)
        }
        .padding(.horizontal, OnboardingMetrics.lg)
        .padding(.vertical, compact ? OnboardingMetrics.sm : OnboardingMetrics.md)
        .accessibilityElement(children: .combine)
    }
}

/// The card that holds a page's feature rows.
struct OnboardingFeatureCard<Rows: View>: View {
    private let rows: Rows

    // The rows are built here, once, on the main actor (not in a closure the layout may call
    // later): `ViewThatFits` measures its alternatives on SwiftUI's async renderer, and a
    // main-actor closure evaluated there trips libdispatch's queue assertion.
    init(@ViewBuilder rows: () -> Rows) {
        self.rows = rows()
    }

    var body: some View {
        VStack(spacing: 0) { rows }
            .frame(maxWidth: .infinity)
            .onboardingCard()
    }
}

/// An inset divider between feature rows.
struct OnboardingRowDivider: View {
    var body: some View {
        Divider().padding(.leading, OnboardingMetrics.lg)
    }
}

// MARK: - Fold-aware columns

/// Stacks a page's header over its body; on an unfolded iPhone Duo (or whenever a hinge divides
/// the window) puts the header in the leading half and the body in the trailing half, with a
/// gap around the hinge.
struct OnboardingColumns<Lead: View, Trail: View>: View {
    let probe: LayoutProbe
    /// Pins the header to the top of the two columns (used when the page scrolls, so a tall body
    /// cannot push the centred header out of view).
    var topAligned = false
    private let lead: Lead
    private let trail: Trail

    init(probe: LayoutProbe, topAligned: Bool = false, @ViewBuilder lead: () -> Lead, @ViewBuilder trail: () -> Trail) {
        self.probe = probe
        self.topAligned = topAligned
        self.lead = lead()
        self.trail = trail()
    }

    var body: some View {
        if let split = OnboardingSplit(probe) {
            HStack(alignment: topAligned ? .top : .center, spacing: 0) {
                lead
                    .padding(.horizontal, OnboardingMetrics.lg)
                    .frame(width: split.leadingWidth)
                Spacer(minLength: 0)
                trail
                    .frame(maxWidth: OnboardingMetrics.readableWidth)
                    .padding(.horizontal, OnboardingMetrics.lg)
                    .frame(width: split.trailingWidth)
            }
            .frame(maxHeight: .infinity)
        } else {
            VStack(spacing: OnboardingMetrics.xl) {
                lead
                trail
            }
        }
    }
}

/// The two column widths either side of a vertical hardware fold.
struct OnboardingSplit {
    let leadingWidth: CGFloat
    let trailingWidth: CGFloat
    /// Distance from the container's leading edge to where the trailing column starts.
    let trailingOffset: CGFloat

    init?(_ probe: LayoutProbe) {
        guard probe.hasFold, let x = probe.foldCenterX else { return nil }
        // Keep clear of the hinge: a wider gap while the device is partially open.
        let gap = probe.isFoldActive ? OnboardingMetrics.xxl * 2 : OnboardingMetrics.xxl
        leadingWidth = max(0, x - gap)
        trailingWidth = max(0, probe.width - x - gap)
        trailingOffset = x + gap
    }
}
#endif
