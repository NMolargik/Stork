//
//  JarView.swift
//  Stork
//
//  Created by Nick Molargik on 10/4/25.
//

import SwiftUI
import SpriteKit

struct JarView: View {
    let boyCount: Int
    let girlCount: Int
    let lossCount: Int
    var monthLabel: String? = nil
    @Binding var reshuffle: Bool

    private let cornerRadius: CGFloat = 12
    @State private var showHistory = false

    @State private var scene = {
        let s = MarbleScene()
        s.scaleMode = .resizeFill
        return s
    }()
    @State private var containerSize: CGSize = .zero
    @Environment(\.horizontalSizeClass) private var hSizeClass

    @State private var prevBoy = 0
    @State private var prevGirl = 0
    @State private var prevLoss = 0
    @State private var didInitialDrop = false
    @State private var startupIgnoreUntil: Date? = nil
    @State private var hasCompletedInitialSpawn = false
    @State private var sizeClassDebounceTask: Task<Void, Never>? = nil

    @Environment(\.colorScheme) private var colorScheme
    private let tilt = TiltManager()
    @State private var isMotionActive = false
    @State private var isVisible = true

    var body: some View {
        GeometryReader { proxy in
            let newSize = proxy.size
            let globalFrame = proxy.frame(in: .global)

            TransparentSpriteView(scene: scene)
                .ignoresSafeArea(edges: .bottom)
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                .modifier(JarGlassBackground(cornerRadius: cornerRadius))
            .onChange(of: newSize) { _, new in
                let sizeChanged = containerSize != new
                containerSize = new
                _ = sizeChanged // keep tracking size changes, but no reset here
            }
            .onChange(of: globalFrame) { _, frame in
                updateVisibility(for: frame)
            }
            .onAppear {
                updateVisibility(for: globalFrame)
            }
        }
        .overlay(alignment: .top) {
            if let monthLabel {
                Text(monthLabel)
                    .font(.body.weight(.semibold))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .modifier(JarLabelBackground())
                    .padding(.top, 8)
            } else {
                Button {
                    showHistory = true
                } label: {
                    HStack(spacing: 4) {
                        Text(monthText())
                            .font(.body.weight(.semibold))
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.semibold))
                    }
                    .foregroundStyle(.gray)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .modifier(JarLabelBackground())
                }
                #if os(visionOS)
                .buttonStyle(.plain)
                #endif
                .padding(.top, 8)
            }
        }
        .sheet(isPresented: $showHistory) {
            JarHistoryView()
                .presentationDetents([.medium])
                .interactiveDismissDisabled()
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Delivery jar for \(monthLabel ?? monthText())")
        .accessibilityValue("\(boyCount) boys, \(girlCount) girls, \(lossCount) losses")
        .accessibilityHint(monthLabel == nil ? "Tap month label to view jar history" : "")
        .onAppear {
            startupIgnoreUntil = Date().addingTimeInterval(2.0)
            // Disable SpriteKit frost when SwiftUI liquid glass handles it
            if #available(iOS 26.0, *) {
                scene.useFrostEffect = false
            }
            scene.onReady = { [weak scene] in
                guard let scene = scene else { return }
                scene.applyAppearance(isDark: colorScheme == .dark)
                ensureInitialDropIfNeeded()
                dropDeltasIfNeeded()
                hasCompletedInitialSpawn = true
            }
            scene.containerCornerRadius = cornerRadius
            scene.applyAppearance(isDark: colorScheme == .dark)
            // Tilt and physics are managed by visibility handler
        }
        .onDisappear {
            if isMotionActive {
                tilt.stop()
                isMotionActive = false
            }
        }
        .onChange(of: boyCount) { _, _ in
            ensureInitialDropIfNeeded()
            dropDeltasIfNeeded()
        }
        .onChange(of: girlCount) { _, _ in
            ensureInitialDropIfNeeded()
            dropDeltasIfNeeded()
        }
        .onChange(of: lossCount) { _, _ in
            ensureInitialDropIfNeeded()
            dropDeltasIfNeeded()
        }
        .onChange(of: reshuffle) { _, should in
            print("Reshuffling")
            guard should else { return }
            // Full reset + respawn to guarantee exact counts after a manual reshuffle trigger.
            scene.resetAndRespawn(blue: boyCount, pink: girlCount, purple: lossCount) {
                prevBoy = boyCount
                prevGirl = girlCount
                prevLoss = lossCount
                didInitialDrop = true
            }
            DispatchQueue.main.async { self.reshuffle = false }
        }
        .onChange(of: colorScheme) { _, _ in
            scene.applyAppearance(isDark: colorScheme == .dark)
        }
        .onChange(of: hSizeClass) { _, _ in
            // Debounce a full reset so we only refresh once after the size-class settles.
            sizeClassDebounceTask?.cancel()
            sizeClassDebounceTask = Task { @MainActor in
                try? await Task.sleep(nanoseconds: 350_000_000) // ~0.35s
                scene.resetAndRespawn(blue: boyCount, pink: girlCount, purple: lossCount) {
                    prevBoy = boyCount
                    prevGirl = girlCount
                    prevLoss = lossCount
                    didInitialDrop = true
                }
            }
        }
    }

    private func ensureInitialDropIfNeeded() {
        // Only perform the initial drop if we haven't done it, there is something to drop,
        // and the scene isn't already in a populated state representing the current counts.
        guard !didInitialDrop else { return }
        print("Initial Drop!")
        let expectedTotal = boyCount + girlCount + lossCount
        guard expectedTotal > 0 else { return }

        if scene.hasAnyMarbles() {
            // Scene already populated (e.g., due to a reset/respawn during startup).
            // Just sync counters to avoid a second initial drop.
            prevBoy = boyCount
            prevGirl = girlCount
            prevLoss = lossCount
            didInitialDrop = true
            return
        }

        // No marbles yet — perform the initial drop.
        scene.enqueue(blue: boyCount, pink: girlCount, purple: lossCount)
        prevBoy = boyCount
        prevGirl = girlCount
        prevLoss = lossCount
        didInitialDrop = true
    }

    private func dropDeltasIfNeeded() {
        let dBoy = max(0, boyCount - prevBoy)
        let dGirl = max(0, girlCount - prevGirl)
        let dLoss = max(0, lossCount - prevLoss)

        scene.enqueue(blue: dBoy, pink: dGirl, purple: dLoss)

        prevBoy = boyCount
        prevGirl = girlCount
        prevLoss = lossCount
    }

    private func monthText() -> String {
        let df = DateFormatter()
        df.locale = .current
        df.dateFormat = "LLLL" // full month name
        return df.string(from: Date())
    }

    private func updateVisibility(for frame: CGRect) {
        // Get screen/window bounds
        #if os(iOS)
        let screenHeight = UIScreen.main.bounds.height
        #else
        let screenHeight: CGFloat = 1200
        #endif

        // Check if any part of the jar is visible on screen
        // Add some padding to avoid flickering at edges
        let visibleThreshold: CGFloat = -50
        let nowVisible = frame.maxY > visibleThreshold && frame.minY < screenHeight + 50

        if nowVisible != isVisible {
            isVisible = nowVisible
            scene.isPaused = !nowVisible

            // Also pause/resume tilt when visibility changes
            if nowVisible {
                if !isMotionActive {
                    isMotionActive = true
                    tilt.start { x in
                        let horizontalG = max(-0.5, min(0.5, x))
                        let dx = CGFloat(horizontalG * 6.0)
                        DispatchQueue.main.async {
                            self.scene.physicsWorld.gravity = CGVector(dx: dx, dy: -9.8)
                        }
                    }
                }
            } else {
                if isMotionActive {
                    tilt.stop()
                    isMotionActive = false
                }
            }
        }
    }
}

// MARK: - Glass Modifiers

private struct JarGlassBackground: ViewModifier {
    let cornerRadius: CGFloat

    func body(content: Content) -> some View {
        #if os(iOS)
        if #available(iOS 26.0, *) {
            content
                .glassEffect(.regular, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        } else {
            jarFallback(content: content)
        }
        #else
        jarFallback(content: content)
        #endif
    }

    private func jarFallback(content: Content) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(.ultraThinMaterial)
                .allowsHitTesting(false)
            content
                .overlay {
                    Rectangle()
                        .foregroundStyle(.ultraThinMaterial)
                        .opacity(0.6)
                        .allowsHitTesting(false)
                }
        }
    }
}

private struct JarLabelBackground: ViewModifier {
    func body(content: Content) -> some View {
        #if os(iOS)
        if #available(iOS 26.0, *) {
            content
                .glassEffect(.regular, in: Capsule())
        } else {
            content
                .background(.thinMaterial, in: Capsule())
                .shadow(radius: 1)
        }
        #else
        content
            .background(.thinMaterial, in: Capsule())
            .shadow(radius: 1)
        #endif
    }
}

// MARK: - Preview
#Preview {
    struct Demo: View {
        @State private var boys = 8
        @State private var girls = 6
        @State private var losses = 3
        @State private var reshuffle = false

        var body: some View {
            VStack(spacing: 12) {
                JarView(boyCount: boys, girlCount: girls, lossCount: losses, reshuffle: $reshuffle)
                    .frame(height: 360)
                    .padding()

                HStack {
                    Stepper("Boys: \(boys)", value: $boys, in: 0...200)
                    Stepper("Girls: \(girls)", value: $girls, in: 0...200)
                    Stepper("Loss: \(losses)", value: $losses, in: 0...200)
                }
                .padding(.horizontal)

                Button("Reshuffle") { reshuffle = true }
            }
        }
    }
    return Demo()
}
