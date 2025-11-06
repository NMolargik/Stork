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
    @Binding var reshuffle: Bool

    private let cornerRadius: CGFloat = 12

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

    var body: some View {
        GeometryReader { proxy in
            let newSize = proxy.size
            ZStack {
                // A subtle glassy background
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.ultraThinMaterial)
                    .allowsHitTesting(false)
                TransparentSpriteView(scene: scene)
                    .overlay {
                        Rectangle()
                            .foregroundStyle(.ultraThinMaterial)
                            .opacity(0.6)
                            .allowsHitTesting(false)
                    }
                    .ignoresSafeArea(edges: .bottom)
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            }
            .onChange(of: newSize) { _, new in
                let sizeChanged = containerSize != new
                containerSize = new
                _ = sizeChanged // keep tracking size changes, but no reset here
            }
        }
        .overlay(alignment: .top) {
            Text(monthText())
                .font(.body.weight(.semibold))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(.thinMaterial, in: Capsule())
                .shadow(radius: 1)
                .padding(.top, 8)
        }
        .onAppear {
            startupIgnoreUntil = Date().addingTimeInterval(2.0)
            scene.onReady = { [weak scene] in
                guard let scene = scene else { return }
                scene.applyAppearance(isDark: colorScheme == .dark)
                ensureInitialDropIfNeeded()
                dropDeltasIfNeeded()
                hasCompletedInitialSpawn = true
            }
            scene.containerCornerRadius = cornerRadius
            scene.applyAppearance(isDark: colorScheme == .dark)
            if !isMotionActive {
                isMotionActive = true
                tilt.start { x in
                    let horizontalG = max(-0.5, min(0.5, x)) // clamp
                    let dx = CGFloat(horizontalG * 6.0)     // subtle push
                    DispatchQueue.main.async {
                        scene.physicsWorld.gravity = CGVector(dx: dx, dy: -9.8)
                    }
                }
            }
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
