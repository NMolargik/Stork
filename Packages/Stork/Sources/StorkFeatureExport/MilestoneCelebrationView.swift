//
//  MilestoneCelebrationView.swift
//  StorkFeatureExport
//
//  Full-screen celebration overlay with confetti when a career milestone is crossed.
//

#if os(iOS)
import SwiftUI
import StorkCore
import StorkDesignSystem

public struct MilestoneCelebrationView: View {
    private let milestone: MilestoneCelebration
    private let onDismiss: () -> Void
    private let onShare: () -> Void

    @State private var showContent = false
    @State private var confettiPieces: [ConfettiPiece] = []

    private let confettiColors: [Color] = [.storkBlue, .storkPink, .storkPurple, .storkOrange, .yellow, .green]

    public init(milestone: MilestoneCelebration, onDismiss: @escaping () -> Void, onShare: @escaping () -> Void) {
        self.milestone = milestone
        self.onDismiss = onDismiss
        self.onShare = onShare
    }

    public var body: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture { dismissWithAnimation() }

            GeometryReader { _ in
                ForEach(confettiPieces) { ConfettiPieceView(piece: $0) }
            }
            .ignoresSafeArea()
            .accessibilityHidden(true)

            VStack(spacing: 24) {
                Image(systemName: "star.fill")
                    .font(.system(size: 60)).foregroundStyle(.yellow)
                    .shadow(color: .yellow.opacity(0.6), radius: 20)
                    .scaleEffect(showContent ? 1.0 : 0.3)
                    .rotationEffect(.degrees(showContent ? 0 : -30))
                    .accessibilityHidden(true)

                VStack(spacing: 8) {
                    Text(prefixText).font(.title3).foregroundStyle(.secondary)
                    Text("\(milestone.count)")
                        .font(.system(size: 72, weight: .bold, design: .rounded))
                        .foregroundStyle(LinearGradient(colors: [.storkBlue, .storkPurple], startPoint: .leading, endPoint: .trailing))
                    Text(suffixText).font(.title3).foregroundStyle(.secondary)
                }
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 20)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(prefixText) \(milestone.count) \(suffixText)")

                VStack(spacing: 12) {
                    Button {
                        onShare()
                    } label: {
                        Label("Share Achievement", systemImage: "square.and.arrow.up")
                            .font(.headline).foregroundStyle(.white).frame(maxWidth: .infinity).padding(.vertical, 14)
                            .background(LinearGradient(colors: [.storkBlue, .storkPurple], startPoint: .leading, endPoint: .trailing))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    Button {
                        dismissWithAnimation()
                    } label: {
                        Text("Continue")
                            .font(.headline).foregroundStyle(.primary).frame(maxWidth: .infinity).padding(.vertical, 14)
                            .background(Color(uiColor: .tertiarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 30)

                Image("storkicon").resizable().scaledToFit().frame(width: 24, height: 24).accessibilityHidden(true)
            }
            .padding(32)
            .frame(maxWidth: 340)
            .background(RoundedRectangle(cornerRadius: 28, style: .continuous).fill(Color(uiColor: .systemBackground)))
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .strokeBorder(LinearGradient(colors: [.white.opacity(0.3), .clear], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 2)
            )
            .shadow(color: .black.opacity(0.3), radius: 30, x: 0, y: 20)
            .scaleEffect(showContent ? 1.0 : 0.8)
            .opacity(showContent ? 1 : 0)
        }
        .onAppear { startAnimations() }
    }

    private var prefixText: String {
        switch milestone.type {
        case .babies: "You've delivered"
        case .deliveries: "You've completed"
        }
    }

    private var suffixText: String {
        switch milestone.type {
        case .babies: milestone.count == 1 ? "baby!" : "babies!"
        case .deliveries: milestone.count == 1 ? "delivery!" : "deliveries!"
        }
    }

    private func startAnimations() {
        confettiPieces = (0..<100).map { _ in
            ConfettiPiece(color: confettiColors.randomElement() ?? .storkBlue,
                          startX: CGFloat.random(in: 0...1), startY: CGFloat.random(in: -0.3...0),
                          rotation: Double.random(in: 0...360), scale: CGFloat.random(in: 0.5...1.2))
        }
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) { showContent = true }
        Haptics.heavyImpact()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { Haptics.mediumImpact() }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { Haptics.lightImpact() }
    }

    private func dismissWithAnimation() {
        withAnimation(.easeIn(duration: 0.2)) { showContent = false }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { onDismiss() }
    }
}

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
    private let shapeType = Int.random(in: 0...2)

    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            ConfettiShapeView(shapeType: shapeType, color: piece.color)
                .frame(width: 10 * piece.scale, height: 14 * piece.scale)
                .rotationEffect(.degrees(piece.rotation + (animate ? 360 : 0)))
                .position(x: size.width * (animate ? piece.endX : piece.startX), y: size.height * (animate ? piece.endY : piece.startY))
                .opacity(animate ? 0 : 1)
                .onAppear {
                    withAnimation(.easeOut(duration: Double.random(in: 2.5...4.0)).delay(Double.random(in: 0...0.3))) {
                        animate = true
                    }
                }
        }
    }

    private struct ConfettiShapeView: View {
        let shapeType: Int
        let color: Color

        var body: some View {
            switch shapeType {
            case 0: Circle().fill(color)
            case 1: Rectangle().fill(color)
            default: Capsule().fill(color)
            }
        }
    }
}
#endif
