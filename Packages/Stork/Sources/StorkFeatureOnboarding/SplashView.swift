//
//  SplashView.swift
//  StorkFeatureOnboarding
//
//  The first screen on a fresh install: the Stork jar mark, the name, one line of value, and a
//  single "Get Started", on the plain grouped background. The mark sits where the launch
//  screen centres it (same size, same position), so the launch screen hands off in place; then
//  the title and the button fade up. Reduce Motion shows everything at once. On an iPhone Duo
//  with a hinge (unfolded) the mark takes the leading half and the text and button the trailing
//  half, so nothing sits in the fold.
//

#if os(iOS)
import SwiftUI
import StorkDesignSystem

public struct SplashView: View {
    private let onContinue: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var rawProbe = LayoutProbe()
    @State private var trailingInset: CGFloat = 0
    @State private var buttonTop: CGFloat = .greatestFiniteMagnitude
    @State private var textHeight: CGFloat = 0

    @State private var showsText = SplashView.hasPlayedEntrance
    @State private var showsButton = SplashView.hasPlayedEntrance

    /// The entrance runs once per launch, not again when the splash is shown again.
    private static var hasPlayedEntrance = false

    private var probe: LayoutProbe { rawProbe.withDebugFold() }

    public init(onContinue: @escaping () -> Void) {
        self.onContinue = onContinue
    }

    public var body: some View {
        ZStack {
            onboardingBackground.ignoresSafeArea()

            GeometryReader { proxy in
                if let foldX = probe.foldCenterX, probe.hasFold {
                    foldedLayout(size: proxy.size, foldX: foldX)
                } else {
                    flatLayout(size: proxy.size)
                }
            }
            .ignoresSafeArea()
        }
        .containerLayoutProbe { rawProbe = $0 }
        .onGeometryChange(for: CGFloat.self) { $0.safeAreaInsets.trailing } action: { trailingInset = $0 }
        .onAppear(perform: runEntrance)
    }

    // MARK: Flat layout (iPhone, iPad, folded Duo)

    private func flatLayout(size: CGSize) -> some View {
        // The Duo's vertical bar takes the trailing edge: centre in what is left of it.
        let usable = size.width - (probe.hasVerticalBar ? trailingInset : 0)
        let side = markSide(height: size.height)
        let textTop = size.height / 2 + side / 2 + OnboardingMetrics.xxl
        let textRoom = max(0, buttonTop - textTop - OnboardingMetrics.md)

        return ZStack {
            // The mark sits at the exact centre of the full screen, the point the launch
            // screen centres its image on.
            mark
                .frame(width: side, height: side)
                .position(x: usable / 2, y: size.height / 2)

            titleBlock
                .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { textHeight = $0 }
                // Between the centred mark and the button there is only so much room: at very
                // large text sizes the block scales down to fit rather than running into the button.
                .scaleEffect(textHeight > textRoom && textHeight > 0 ? textRoom / textHeight : 1, anchor: .top)
                .opacity(showsText ? 1 : 0)
                .offset(y: showsText ? 0 : 10)
                .frame(maxWidth: OnboardingMetrics.readableWidth)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .padding(.top, textTop)
                .padding(.horizontal, OnboardingMetrics.xl)
                .frame(width: usable)
                .frame(maxWidth: .infinity, alignment: .leading)

            VStack(spacing: 0) {
                Spacer(minLength: 0)
                startButton
                    .padding(.bottom, OnboardingMetrics.lg)
            }
            .padding(.horizontal, OnboardingMetrics.xl)
            .padding(.vertical, OnboardingMetrics.xxl)
            .frame(maxWidth: OnboardingMetrics.readableWidth)
            .frame(width: usable)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        }
    }

    // MARK: Folded layout (unfolded Duo)

    private func foldedLayout(size: CGSize, foldX: CGFloat) -> some View {
        let gap = OnboardingMetrics.xxl
        let leadingWidth = max(0, foldX - gap)
        // The same trailing column as the onboarding pages (`OnboardingSplit`): measured in the
        // container's own width, so the Duo's vertical bar at the edge is not counted, and the
        // button gets the same width and insets as the Continue button.
        let barInset = max(0, size.width - probe.width)
        let trailingWidth = max(0, probe.width - foldX - gap)
        let side = min(Self.launchMarkSide(regular: false), leadingWidth * 0.7)

        return HStack(spacing: 0) {
            mark
                .frame(width: side, height: side)
                .frame(width: leadingWidth, height: size.height)

            Spacer(minLength: 0)

            VStack(spacing: OnboardingMetrics.xl) {
                titleBlock
                    .opacity(showsText ? 1 : 0)
                    .offset(y: showsText ? 0 : 10)
                startButton
                    .frame(maxWidth: OnboardingMetrics.readableWidth)
            }
            .padding(.horizontal, OnboardingMetrics.lg)
            .frame(width: trailingWidth, height: size.height)
        }
        .padding(.trailing, barInset)
    }

    // MARK: Pieces

    private var mark: some View {
        StorkMark()
            .accessibilityLabel(Text("Stork app logo", bundle: .module))
    }

    private var titleBlock: some View {
        VStack(spacing: OnboardingMetrics.md) {
            Text("Stork", bundle: .module)
                .font(.system(.largeTitle, design: .rounded, weight: .bold))
                .accessibilityAddTraits(.isHeader)
            Text("for labor & delivery professionals", bundle: .module)
                .font(.title3)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .fixedSize(horizontal: false, vertical: true)
        .padding(.horizontal, OnboardingMetrics.lg)
        .accessibilityElement(children: .combine)
    }

    private var startButton: some View {
        Button {
            Haptics.mediumImpact()
            onContinue()
        } label: {
            HStack(spacing: OnboardingMetrics.sm) {
                Text("Get Started", bundle: .module)
                Image(systemName: "arrow.right")
                    .accessibilityHidden(true)
            }
            .font(.headline)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 38)
        }
        .onboardingPrimaryButton()
        .keyboardShortcut(.defaultAction)
        .accessibilityIdentifier("continueButton")
        .accessibilityHint(Text("Tap to begin using Stork", bundle: .module))
        .onGeometryChange(for: CGFloat.self) { $0.frame(in: .global).minY } action: { buttonTop = $0 }
        .opacity(showsButton ? 1 : 0)
        .offset(y: showsButton ? 0 : 10)
    }

    /// The side of the mark on the launch screen (`LaunchScreen.storyboard`): the splash draws
    /// the mark at exactly this size and place so the hand-off is seamless.
    private static func launchMarkSide(regular: Bool) -> CGFloat { regular ? 216 : 180 }

    private func markSide(height: CGFloat) -> CGFloat {
        // Fixed (not scaled with Dynamic Type) to match the launch screen; on a short window
        // (the folded Duo) it leaves room for the text under it.
        min(Self.launchMarkSide(regular: horizontalSizeClass == .regular), height * 0.27)
    }

    // MARK: Entrance

    private func runEntrance() {
        #if DEBUG
        // Simulator verification: `-StorkOnboardingStep N` skips straight to that page.
        if UserDefaults.standard.object(forKey: "StorkOnboardingStep") != nil {
            onContinue()
            return
        }
        #endif
        guard !Self.hasPlayedEntrance else { return }
        Self.hasPlayedEntrance = true
        guard !reduceMotion else {
            showsText = true
            showsButton = true
            return
        }
        withAnimation(.easeOut(duration: 0.4).delay(0.25)) { showsText = true }
        withAnimation(.easeOut(duration: 0.35).delay(0.45)) { showsButton = true }
    }
}

#if DEBUG
#Preview("Splash") {
    SplashView(onContinue: {})
}
#endif
#endif
