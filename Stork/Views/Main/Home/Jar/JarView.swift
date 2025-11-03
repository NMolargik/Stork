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

    @State private var prevBoy = 0
    @State private var prevGirl = 0
    @State private var prevLoss = 0
    @State private var didInitialDrop = false

    @Environment(\.colorScheme) private var colorScheme
    private let tilt = TiltManager()
    @State private var isMotionActive = false

    var body: some View {
        ZStack {
            // A subtle glassy background
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(.ultraThinMaterial)
            TransparentSpriteView(scene: scene)
                .overlay {
                    Rectangle()
                        .foregroundStyle(.ultraThinMaterial)
                        .opacity(0.6)
                }
                .ignoresSafeArea(edges: .bottom)
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
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
            scene.onReady = { [weak scene] in
                guard let scene = scene else { return }
                scene.applyAppearance(isDark: colorScheme == .dark)
                ensureInitialDropIfNeeded()
                dropDeltasIfNeeded()
            }
            // If scene is already ready (didMove(to:) already ran), drop immediately to avoid race
            if scene.size.width > 10, scene.size.height > 10, scene.physicsBody != nil {
                ensureInitialDropIfNeeded()
                dropDeltasIfNeeded()
            }
            scene.containerCornerRadius = cornerRadius
            scene.applyAppearance(isDark: colorScheme == .dark)
            dropDeltasIfNeeded()
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
            guard should else { return }
            dropDeltasIfNeeded()
            DispatchQueue.main.async { self.reshuffle = false }
        }
        .onChange(of: colorScheme) { _, _ in
            scene.applyAppearance(isDark: colorScheme == .dark)
        }
    }

    private func ensureInitialDropIfNeeded() {
        guard !didInitialDrop else { return }
        let total = boyCount + girlCount + lossCount
        guard total > 0 else { return }
        // If scene is not ready yet, enqueue will buffer; otherwise it will spawn now
        if !scene.hasAnyMarbles() {
            scene.enqueue(blue: boyCount, pink: girlCount, purple: lossCount)
            prevBoy = boyCount
            prevGirl = girlCount
            prevLoss = lossCount
            didInitialDrop = true
        }
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
