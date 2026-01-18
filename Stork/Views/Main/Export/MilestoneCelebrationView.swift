//
//  MilestoneCelebrationView.swift
//  Stork
//
//  Created by Nick Molargik on 1/17/26.
//

import SwiftUI

struct MilestoneCelebrationView: View {
    let milestone: DeliveryManager.MilestoneCelebration
    let userName: String?
    let onDismiss: () -> Void
    let onShare: () -> Void

    @State private var showContent = false
    @State private var showConfetti = false
    @State private var confettiPieces: [ConfettiPiece] = []

    private let confettiColors: [Color] = [
        .storkBlue, .storkPink, .storkPurple, .storkOrange, .yellow, .green
    ]

    var body: some View {
        ZStack {
            // Dimmed background
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture {
                    dismissWithAnimation()
                }

            // Confetti layer
            GeometryReader { geo in
                ForEach(confettiPieces) { piece in
                    ConfettiPieceView(piece: piece)
                }
            }
            .ignoresSafeArea()

            // Main card
            VStack(spacing: 24) {
                // Animated star
                Image(systemName: "star.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.yellow)
                    .shadow(color: .yellow.opacity(0.6), radius: 20)
                    .scaleEffect(showContent ? 1.0 : 0.3)
                    .rotationEffect(.degrees(showContent ? 0 : -30))

                // Milestone text
                VStack(spacing: 8) {
                    Text(prefixText)
                        .font(.title3)
                        .foregroundStyle(.secondary)

                    Text("\(milestone.count)")
                        .font(.system(size: 72, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.storkBlue, .storkPurple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )

                    Text(suffixText)
                        .font(.title3)
                        .foregroundStyle(.secondary)

                    if let name = userName, !name.isEmpty {
                        Text("Congratulations, \(name)!")
                            .font(.headline)
                            .foregroundStyle(.tertiary)
                            .padding(.top, 4)
                    }
                }
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 20)

                // Action buttons
                VStack(spacing: 12) {
                    Button {
                        onShare()
                    } label: {
                        Label("Share Achievement", systemImage: "square.and.arrow.up")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                LinearGradient(
                                    colors: [.storkBlue, .storkPurple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    Button {
                        dismissWithAnimation()
                    } label: {
                        Text("Continue")
                            .font(.headline)
                            .foregroundStyle(.primary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color(uiColor: .tertiarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 30)

                // Branding
                Image("storkicon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .opacity(0.5)
            }
            .padding(32)
            .frame(maxWidth: 340)
            .background(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(Color(uiColor: .systemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [.white.opacity(0.3), .clear],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
            )
            .shadow(color: .black.opacity(0.3), radius: 30, x: 0, y: 20)
            .scaleEffect(showContent ? 1.0 : 0.8)
            .opacity(showContent ? 1 : 0)
        }
        .onAppear {
            startAnimations()
        }
    }

    private var prefixText: String {
        switch milestone.type {
        case .babies:
            return "You've delivered"
        case .deliveries:
            return "You've completed"
        }
    }

    private var suffixText: String {
        switch milestone.type {
        case .babies:
            return milestone.count == 1 ? "baby!" : "babies!"
        case .deliveries:
            return milestone.count == 1 ? "delivery!" : "deliveries!"
        }
    }

    private func startAnimations() {
        // Generate confetti pieces
        confettiPieces = (0..<100).map { _ in
            ConfettiPiece(
                color: confettiColors.randomElement() ?? .storkBlue,
                startX: CGFloat.random(in: 0...1),
                startY: CGFloat.random(in: -0.3...0),
                rotation: Double.random(in: 0...360),
                scale: CGFloat.random(in: 0.5...1.2)
            )
        }

        // Animate content appearance
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
            showContent = true
        }

        // Start confetti
        withAnimation(.easeOut(duration: 0.1)) {
            showConfetti = true
        }

        // Haptic feedback
        Haptics.heavyImpact()

        // Additional haptic bursts
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            Haptics.mediumImpact()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            Haptics.lightImpact()
        }
    }

    private func dismissWithAnimation() {
        withAnimation(.easeIn(duration: 0.2)) {
            showContent = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            onDismiss()
        }
    }
}

// MARK: - Confetti Piece

struct ConfettiPiece: Identifiable {
    let id = UUID()
    let color: Color
    let startX: CGFloat
    let startY: CGFloat
    let rotation: Double
    let scale: CGFloat

    var endY: CGFloat { 1.3 }
    var endX: CGFloat { startX + CGFloat.random(in: -0.2...0.2) }
}

struct ConfettiPieceView: View {
    let piece: ConfettiPiece

    @State private var animate = false

    // Store shape type at init time so it doesn't change during animation
    private let shapeType: Int = Int.random(in: 0...2)

    var body: some View {
        GeometryReader { geo in
            let size = geo.size

            confettiShapeView
                .frame(width: 10 * piece.scale, height: 14 * piece.scale)
                .rotationEffect(.degrees(piece.rotation + (animate ? 360 : 0)))
                .position(
                    x: size.width * (animate ? piece.endX : piece.startX),
                    y: size.height * (animate ? piece.endY : piece.startY)
                )
                .opacity(animate ? 0 : 1)
                .onAppear {
                    withAnimation(
                        .easeOut(duration: Double.random(in: 2.5...4.0))
                        .delay(Double.random(in: 0...0.3))
                    ) {
                        animate = true
                    }
                }
        }
    }

    @ViewBuilder
    private var confettiShapeView: some View {
        switch shapeType {
        case 0:
            Circle().fill(piece.color)
        case 1:
            Rectangle().fill(piece.color)
        default:
            Capsule().fill(piece.color)
        }
    }
}

#Preview("500 Babies Milestone") {
    MilestoneCelebrationView(
        milestone: DeliveryManager.MilestoneCelebration(count: 500, type: .babies),
        userName: "Sarah Johnson",
        onDismiss: {},
        onShare: {}
    )
}

#Preview("100 Deliveries Milestone") {
    MilestoneCelebrationView(
        milestone: DeliveryManager.MilestoneCelebration(count: 100, type: .deliveries),
        userName: nil,
        onDismiss: {},
        onShare: {}
    )
}
