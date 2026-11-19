//
//  OnboardingView.swift
//  StorkFeatureOnboarding
//
//  The paged first-run flow after the splash: privacy, step count, all set. One page per
//  `OnboardingStep`, slid horizontally, with the primary button pinned below the page and Back
//  as a toolbar item. The Step Count page is skipped where it can't work (Mac/Vision), and its
//  permission request works as before: Continue asks, the next Continue moves on ("Not Now"
//  moves on without asking).
//
//  On an iPhone Duo the toolbar is the vertical strip on the trailing edge; unfolded, the page
//  header and body take the two halves either side of the hinge. iPad in regular width gets the
//  same two columns, split down the middle.
//

#if os(iOS)
import SwiftUI
import UIKit
import StorkCore
import StorkDesignSystem
import StorkServices

public struct OnboardingView: View {
    @Environment(HealthManager.self) private var healthManager
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    private let onFinished: () -> Void
    @State private var model = OnboardingModel()
    @State private var rawProbe = LayoutProbe()

    public init(onFinished: @escaping () -> Void = {}) {
        self.onFinished = onFinished
    }

    private var steps: [OnboardingStep] {
        healthManager.isStepTrackingSupported
            ? OnboardingStep.allCases
            : OnboardingStep.allCases.filter { $0 != .health }
    }

    private var step: OnboardingStep { model.currentStep }
    private var currentIndex: Int { steps.firstIndex(of: step) ?? 0 }
    private var isLastStep: Bool { step == .complete }
    private var isFirstStep: Bool { currentIndex == 0 }

    /// The measured layout, plus a synthetic centre split on a wide regular-width window (iPad)
    /// so it gets the same two columns the unfolded Duo does.
    private var probe: LayoutProbe {
        var result = rawProbe.withDebugFold()
        if !result.hasFold, horizontalSizeClass == .regular, result.width >= 700 {
            result.hasFold = true
            result.foldCenterX = result.width / 2
        }
        return result
    }

    private var asksHealthPermission: Bool {
        step == .health && !healthManager.hasRequestedAuthorization
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                onboardingBackground
                    .ignoresSafeArea()
                    .accessibilityHidden(true)

                if let split = OnboardingSplit(probe) {
                    // Unfolded: the progress dots sit at the same spot on every page, centred
                    // in the leading half, whatever the navigation strip does on that page.
                    VStack(spacing: 0) {
                        pages
                        bottomBar
                    }
                    .overlay(alignment: .top) {
                        progress
                            .frame(width: (split.leadingWidth + split.trailingOffset) / 2)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top, OnboardingMetrics.xl)
                    }
                } else {
                    VStack(spacing: 0) {
                        progress
                            .padding(.top, OnboardingMetrics.xs)
                            .padding(.bottom, OnboardingMetrics.sm)
                        pages
                        bottomBar
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbar }
        }
        .containerLayoutProbe { rawProbe = $0 }
        .onAppear(perform: configure)
        .onChange(of: step) { _, _ in
            AccessibilityNotification.Announcement(step.title).post()
        }
    }

    // MARK: Toolbar

    /// Back is a bar item with a symbol and a title, so it sits in the navigation bar on iPhone
    /// and iPad and moves into the vertical strip on iPhone Duo.
    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        if !isFirstStep {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    goBack()
                } label: {
                    Label(String(localized: "Back", bundle: .module), systemImage: "chevron.backward")
                }
                .keyboardShortcut("[", modifiers: .command)
            }
        } else {
            // The first page keeps an invisible Back so the bar, and with it the progress
            // dots, sit exactly where they do on every other page.
            ToolbarItem(placement: .topBarLeading) {
                Button {} label: { Label(String(localized: "Back", bundle: .module), systemImage: "chevron.backward") }
                    .hidden()
                    .accessibilityHidden(true)
                    .disabled(true)
            }
            .sharedBackgroundVisibility(.hidden)
        }
    }

    // MARK: Progress

    private var progress: some View {
        HStack(spacing: OnboardingMetrics.xs + 2) {
            ForEach(Array(steps.enumerated()), id: \.offset) { index, _ in
                Capsule(style: .continuous)
                    .fill(index == currentIndex ? AnyShapeStyle(Color.storkPurple) : AnyShapeStyle(.tertiary))
                    .frame(width: index == currentIndex ? 24 : 8, height: 8)
                    .overlay(Capsule(style: .continuous).strokeBorder(.quaternary))
            }
        }
        .frame(maxWidth: OnboardingSplit(probe) != nil ? .infinity : nil)
        .animation(reduceMotion ? nil : .spring(response: 0.35, dampingFraction: 0.8), value: step)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("Step \(currentIndex + 1) of \(steps.count)", bundle: .module))
        .accessibilityValue(Text(step.title))
    }

    // MARK: Pages

    private var pages: some View {
        ZStack {
            OnboardingFeaturePage(step: step, probe: probe)
                .id(step)
                .transition(pageTransition)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipped()
        .animation(pageAnimation, value: model.currentStep)
        .simultaneousGesture(swipeGesture)
    }

    private var pageTransition: AnyTransition {
        guard !reduceMotion else { return .opacity }
        let forward = model.direction == .forward
        return .asymmetric(
            insertion: .move(edge: forward ? .trailing : .leading).combined(with: .opacity),
            removal: .move(edge: forward ? .leading : .trailing).combined(with: .opacity)
        )
    }

    private var swipeGesture: some Gesture {
        DragGesture(minimumDistance: 40, coordinateSpace: .local)
            .onEnded { value in
                guard abs(value.translation.width) > abs(value.translation.height) * 1.5 else { return }
                if value.translation.width > 80 { goBack() }
            }
    }

    // MARK: Bottom bar

    /// The primary button, and under it one quiet text button ("Not Now" while Health access is
    /// still undecided). The row keeps its height on every page so the primary button never jumps.
    private var bottomBar: some View {
        VStack(spacing: OnboardingMetrics.sm) {
            Button {
                Haptics.mediumImpact()
                if isLastStep {
                    onFinished()
                } else {
                    // Commit the direction first so the outgoing page slides the right way.
                    model.direction = .forward
                    Task { await model.handleContinueTapped(healthManager: healthManager) }
                }
            } label: {
                HStack(spacing: OnboardingMetrics.sm) {
                    if model.isRequestingPermission {
                        ProgressView().tint(.white)
                    } else {
                        Text(isLastStep ? "Enter Stork" : "Continue", bundle: .module).font(.headline)
                        Image(systemName: isLastStep ? "checkmark" : "arrow.right").font(.headline).accessibilityHidden(true)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(minHeight: 38)
            }
            .onboardingPrimaryButton()
            .keyboardShortcut(.defaultAction)
            .disabled(!model.canContinue)
            .accessibilityIdentifier("continueButton")

            ZStack {
                if asksHealthPermission {
                    Button {
                        Haptics.lightImpact()
                        model.direction = .forward
                        Task { @MainActor in model.skipHealth() }
                    } label: {
                        Text("Not Now", bundle: .module)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, minHeight: 44)
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("skipButton")
                }
            }
            .frame(minHeight: 44)
        }
        .frame(maxWidth: OnboardingMetrics.readableWidth)
        .padding(.horizontal, OnboardingSplit(probe) != nil ? OnboardingMetrics.lg : OnboardingMetrics.xl)
        .padding(.top, OnboardingMetrics.md)
        .padding(.bottom, OnboardingMetrics.sm)
        .frame(width: OnboardingSplit(probe)?.trailingWidth)
        .frame(maxWidth: .infinity, alignment: OnboardingSplit(probe) != nil ? .trailing : .center)
    }

    // MARK: Actions

    private func configure() {
        #if DEBUG
        // Simulator verification: `-StorkOnboardingStep N` (0-based) opens that page.
        if UserDefaults.standard.object(forKey: "StorkOnboardingStep") != nil {
            let page = UserDefaults.standard.integer(forKey: "StorkOnboardingStep")
            if steps.indices.contains(page) { model.currentStep = steps[page] }
        }
        #endif
    }

    private func goBack() {
        guard !isFirstStep else { return }
        model.direction = .backward
        Task { @MainActor in model.goBack(in: steps) }
    }

    private var pageAnimation: Animation {
        reduceMotion ? .easeInOut(duration: 0.2) : .spring(response: 0.45, dampingFraction: 0.86)
    }
}

#if DEBUG
#Preview("Onboarding") {
    OnboardingView()
        .environment(HealthManager())
}

/// The unfolded iPhone Duo (951 x 669 pt, hinge at the middle), rendered by injecting the hinge.
#Preview("Onboarding · unfolded Duo", traits: .fixedLayout(width: 951, height: 669)) {
    let _ = UserDefaults.standard.set(475.5, forKey: "StorkOnboardingFoldX")
    OnboardingView()
        .environment(HealthManager())
        .onDisappear { UserDefaults.standard.removeObject(forKey: "StorkOnboardingFoldX") }
}
#endif
#endif
