//
//  JarView.swift
//  StorkFeatureDashboard
//
//  The marble jar: drops a marble per baby (blue/pink/purple), tilts with device motion,
//  and pauses physics when scrolled offscreen. Tapping the month label opens jar history.
//

#if os(iOS)
import SwiftUI
import SpriteKit
import StorkCore

public struct JarView: View {
    let boyCount: Int
    let girlCount: Int
    let lossCount: Int
    var monthLabel: String?
    /// Optional history destination: tapping the month label presents this.
    var history: AnyView?
    @Binding var reshuffle: Bool

    public init(
        boyCount: Int,
        girlCount: Int,
        lossCount: Int,
        monthLabel: String? = nil,
        history: AnyView? = nil,
        reshuffle: Binding<Bool>
    ) {
        self.boyCount = boyCount
        self.girlCount = girlCount
        self.lossCount = lossCount
        self.monthLabel = monthLabel
        self.history = history
        _reshuffle = reshuffle
    }

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
    @State private var sizeClassDebounceTask: Task<Void, Never>?
    @Environment(\.colorScheme) private var colorScheme
    private let tilt = TiltManager()
    @State private var isMotionActive = false
    @State private var isVisible = false

    public var body: some View {
        GeometryReader { proxy in
            let newSize = proxy.size
            TransparentSpriteView(scene: scene)
                .ignoresSafeArea(edges: .bottom)
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                .modifier(JarGlassBackground(cornerRadius: cornerRadius))
                .onChange(of: newSize) { _, new in containerSize = new }
        }
        .onScrollVisibilityChange(threshold: 0.01) { setVisible($0) }
        .overlay(alignment: .top) {
            MonthOverlay(monthLabel: monthLabel, monthText: monthText(), hasHistory: history != nil, showHistory: $showHistory)
        }
        .sheet(isPresented: $showHistory) {
            if let history {
                history.presentationDetents([.medium])
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Delivery jar for \(monthLabel ?? monthText())")
        .accessibilityValue("\(boyCount) boys, \(girlCount) girls, \(lossCount) losses")
        .onAppear {
            if #available(iOS 26.0, *) { scene.useFrostEffect = false }
            scene.onReady = {
                scene.applyAppearance(isDark: colorScheme == .dark)
                ensureInitialDropIfNeeded()
                dropDeltasIfNeeded()
            }
            scene.containerCornerRadius = cornerRadius
            scene.applyAppearance(isDark: colorScheme == .dark)
        }
        .onDisappear {
            if isMotionActive { tilt.stop(); isMotionActive = false }
        }
        .onChange(of: boyCount) { _, _ in ensureInitialDropIfNeeded(); dropDeltasIfNeeded() }
        .onChange(of: girlCount) { _, _ in ensureInitialDropIfNeeded(); dropDeltasIfNeeded() }
        .onChange(of: lossCount) { _, _ in ensureInitialDropIfNeeded(); dropDeltasIfNeeded() }
        .onChange(of: reshuffle) { _, should in
            guard should else { return }
            scene.resetAndRespawn(blue: boyCount, pink: girlCount, purple: lossCount) {
                prevBoy = boyCount; prevGirl = girlCount; prevLoss = lossCount; didInitialDrop = true
            }
            DispatchQueue.main.async { self.reshuffle = false }
        }
        .onChange(of: colorScheme) { _, _ in scene.applyAppearance(isDark: colorScheme == .dark) }
        .onChange(of: hSizeClass) { _, _ in
            sizeClassDebounceTask?.cancel()
            sizeClassDebounceTask = Task { @MainActor in
                try? await Task.sleep(nanoseconds: 350_000_000)
                scene.resetAndRespawn(blue: boyCount, pink: girlCount, purple: lossCount) {
                    prevBoy = boyCount; prevGirl = girlCount; prevLoss = lossCount; didInitialDrop = true
                }
            }
        }
    }

    private struct MonthOverlay: View {
        let monthLabel: String?
        let monthText: String
        let hasHistory: Bool
        @Binding var showHistory: Bool

        var body: some View {
            if let monthLabel {
                Text(monthLabel)
                    .font(.body.weight(.semibold))
                    .padding(.horizontal, 12).padding(.vertical, 8)
                    .modifier(JarLabelBackground())
                    .padding(.top, 8)
            } else if hasHistory {
                Button {
                    showHistory = true
                } label: {
                    HStack(spacing: 4) {
                        Text(monthText).font(.body.weight(.semibold))
                        Image(systemName: "chevron.right").font(.caption.weight(.semibold))
                    }
                    .foregroundStyle(.gray)
                    .padding(.horizontal, 12).padding(.vertical, 8)
                    .modifier(JarLabelBackground())
                }
                .padding(.top, 8)
            }
        }
    }

    private func ensureInitialDropIfNeeded() {
        guard !didInitialDrop else { return }
        guard boyCount + girlCount + lossCount > 0 else { return }
        if scene.hasAnyMarbles() {
            prevBoy = boyCount; prevGirl = girlCount; prevLoss = lossCount; didInitialDrop = true
            return
        }
        scene.enqueue(blue: boyCount, pink: girlCount, purple: lossCount)
        prevBoy = boyCount; prevGirl = girlCount; prevLoss = lossCount; didInitialDrop = true
    }

    private func dropDeltasIfNeeded() {
        scene.enqueue(blue: max(0, boyCount - prevBoy), pink: max(0, girlCount - prevGirl), purple: max(0, lossCount - prevLoss))
        prevBoy = boyCount; prevGirl = girlCount; prevLoss = lossCount
    }

    private func monthText() -> String {
        let df = DateFormatter()
        df.locale = .current
        df.dateFormat = "LLLL"
        return df.string(from: Date())
    }

    private func setVisible(_ nowVisible: Bool) {
        guard nowVisible != isVisible else { return }
        isVisible = nowVisible
        scene.isPaused = !nowVisible
        if nowVisible {
            if !isMotionActive {
                isMotionActive = true
                tilt.start { x in
                    let horizontalG = max(-0.5, min(0.5, x))
                    scene.physicsWorld.gravity = CGVector(dx: CGFloat(horizontalG * 6.0), dy: -9.8)
                }
            }
        } else if isMotionActive {
            tilt.stop()
            isMotionActive = false
        }
    }
}

private struct JarGlassBackground: ViewModifier {
    let cornerRadius: CGFloat
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content.glassEffect(.regular, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        } else {
            ZStack {
                RoundedRectangle(cornerRadius: cornerRadius).fill(.ultraThinMaterial).allowsHitTesting(false)
                content.overlay {
                    Rectangle().foregroundStyle(.ultraThinMaterial).opacity(0.6).allowsHitTesting(false)
                }
            }
        }
    }
}

private struct JarLabelBackground: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content.glassEffect(.regular, in: Capsule())
        } else {
            content.background(.thinMaterial, in: Capsule()).shadow(radius: 1)
        }
    }
}
#endif
