//
//  MarbleScene.swift
//  Stork
//
//  Created by Nick Molargik on 11/3/25.
//

import SwiftUI
import SpriteKit
import UIKit

final class MarbleScene: SKScene {
    // Helper to check if any marbles exist in the scene
    func hasAnyMarbles() -> Bool {
        var found = false
        enumerateChildNodes(withName: "marble") { _, stop in
            found = true
            stop.pointee = true
        }
        return found
    }
    var containerCornerRadius: CGFloat = 20 { didSet { rebuildWalls() } }
    private let frostNode = SKShapeNode()
    private var spawnY: CGFloat { size.height - 10 }
    private var marbleRadius: CGFloat {
        #if os(iOS)
        if UIDevice.current.userInterfaceIdiom == .pad {
            return max(20, min(size.width, size.height) * 0.025)
        } else {
            return max(18, min(size.width, size.height) * 0.025)
        }
        #else
        return max(18, min(size.width, size.height) * 0.025)
        #endif
    }

    // Callback fired once when the scene is ready (non-zero size & walls built)
    var onReady: (() -> Void)? { didSet { maybeSignalReady() } }
    private var didSignalReady = false

    // Keep walls separate from marbles
    private let wallsNode = SKNode()

    // Colors
    static let boyBlue = SKColor.from(Color("storkBlue"))
    static let girlPink = SKColor.from(Color("storkPink"))
    static let lossPurple = SKColor.from(Color("storkPurple"))

    // Pending marble counts if not ready
    private var pendingBlue = 0
    private var pendingPink = 0
    private var pendingPurple = 0
    private var isReady: Bool { size.width > 10 && size.height > 10 && physicsBody != nil }

    // Lifecycle
    override func didMove(to view: SKView) {
        backgroundColor = .clear
        // Frosted glass effect background (stored node so we can restyle for light/dark)
        frostNode.path = CGPath(rect: CGRect(origin: .zero, size: size), transform: nil)
        frostNode.fillColor = SKColor.white.withAlphaComponent(0.12)
        frostNode.strokeColor = .clear
        frostNode.zPosition = -2
        frostNode.position = .zero
        frostNode.blendMode = .alpha
        if frostNode.parent == nil { addChild(frostNode) }

        physicsWorld.gravity = CGVector(dx: 0, dy: -9.8)
        rebuildWalls()
        maybeSignalReady()
    }

    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        removeAllActions()
        updateFrostFrame()
        rebuildWalls()
        maybeSignalReady()
        if isReady { flushPending() }
    }

    func applyAppearance(isDark: Bool) {
        // Slightly stronger material in dark mode, lighter in light mode
        let alpha: CGFloat = isDark ? 0.18 : 0.08
        frostNode.fillColor = SKColor.white.withAlphaComponent(alpha)
    }

    private func updateFrostFrame() {
        frostNode.path = CGPath(rect: CGRect(origin: .zero, size: size), transform: nil)
        frostNode.position = .zero
    }

    private func rebuildWalls() {
        let inset: CGFloat = 4
        let rect = frame.insetBy(dx: inset, dy: inset)
        let path = CGPath(roundedRect: rect, cornerWidth: containerCornerRadius, cornerHeight: containerCornerRadius, transform: nil)
        physicsBody = SKPhysicsBody(edgeLoopFrom: path)
        physicsBody?.isDynamic = false
    }

    private func maybeSignalReady() {
        guard !didSignalReady, size.width > 10, size.height > 10 else { return }
        guard let onReady else { return } // do not consume readiness until handler exists
        didSignalReady = true
        flushPending()
        DispatchQueue.main.async {
            onReady()
        }
    }
    // Enqueue marbles if not ready, otherwise spawn immediately
    func enqueue(blue: Int, pink: Int, purple: Int) {
        guard blue > 0 || pink > 0 || purple > 0 else { return }
        if !isReady {
            pendingBlue += max(0, blue)
            pendingPink += max(0, pink)
            pendingPurple += max(0, purple)
            return
        }
        if blue > 0 { addMarbles(count: blue, color: MarbleScene.boyBlue) }
        if pink > 0 { addMarbles(count: pink, color: MarbleScene.girlPink) }
        if purple > 0 { addMarbles(count: purple, color: MarbleScene.lossPurple) }
    }

    private func flushPending() {
        let b = pendingBlue; let p = pendingPink; let r = pendingPurple
        pendingBlue = 0; pendingPink = 0; pendingPurple = 0
        if b > 0 { addMarbles(count: b, color: MarbleScene.boyBlue) }
        if p > 0 { addMarbles(count: p, color: MarbleScene.girlPink) }
        if r > 0 { addMarbles(count: r, color: MarbleScene.lossPurple) }
    }

    // MARK: - Spawning
    func addMarbles(count: Int, color: SKColor) {
        guard count > 0 else { return }
        let wait = SKAction.wait(forDuration: 0.04)
        let spawn = SKAction.run { [weak self] in self?.spawnMarble(color: color) }
        run(SKAction.repeat(SKAction.sequence([spawn, wait]), count: count))
    }

    private func spawnMarble(color: SKColor) {
        let radius = marbleRadius
        let xMin = radius
        let xMax = size.width - radius
        let x = CGFloat.random(in: xMin...xMax)
        let y = spawnY

        let node = SKShapeNode(circleOfRadius: radius)
        node.fillColor = color.withAlphaComponent(0.82)
        node.strokeColor = color.withAlphaComponent(0.85)
        node.lineWidth = 1
        node.name = "marble"
        node.position = CGPoint(x: x, y: y)
        node.zPosition = 1

        let body = SKPhysicsBody(circleOfRadius: radius)
        body.mass = 0.02
        body.restitution = 0.35
        body.friction = 0.6
        body.linearDamping = 0.4
        body.angularDamping = 0.4
        node.physicsBody = body

        addChild(node)
    }

    // MARK: - Interaction
    private func blast(at point: CGPoint, strength: CGFloat = 3.5, radius: CGFloat = 140) {
        // Apply an outward impulse to marbles within the radius from 'point'
        enumerateChildNodes(withName: "marble") { node, _ in
            guard let body = node.physicsBody else { return }
            let dx = node.position.x - point.x
            let dy = node.position.y - point.y
            let dist = sqrt(dx*dx + dy*dy)
            guard dist > 1, dist <= radius else { return }
            // Outward, distance-weighted impulse with slight upward bias
            let nx = dx / dist
            let ny = dy / dist
            let falloff = max(0, 1.0 - (dist / radius)) // 1 at center → 0 at edge
            let boost: CGFloat = 1.0 + 0.25 * falloff     // small extra punch near center
            let impulse = strength * falloff * boost
            let ix = nx * impulse
            let iy = ny * impulse + 0.2 * impulse         // nudge upward a bit
            body.applyImpulse(CGVector(dx: ix, dy: iy))
            // Add a touch of spin
            body.applyAngularImpulse((Bool.random() ? 1 : -1) * 0.02 * impulse)
        }
    }

    // Remove all existing marbles (preserve walls)
    func clearMarbles() {
        enumerateChildNodes(withName: "marble") { node, _ in
            node.removeFromParent()
        }
    }

    func resetAndRespawn(blue: Int, pink: Int, purple: Int, completion: @escaping () -> Void) {
        removeAllActions()
        clearMarbles()

        // Spawn in a round-robin pattern for visual variety
        var queue: [SKColor] = []
        queue += Array(repeating: MarbleScene.boyBlue, count: blue)
        queue += Array(repeating: MarbleScene.girlPink, count: pink)
        queue += Array(repeating: MarbleScene.lossPurple, count: purple)
        queue.shuffle()

        guard !queue.isEmpty else { completion(); return }

        let wait = SKAction.wait(forDuration: 0.04)
        var actions: [SKAction] = []
        for color in queue {
            actions.append(.run { [weak self] in self?.spawnMarble(color: color) })
            actions.append(wait)
        }
        actions.append(.run(completion))
        run(.sequence(actions))
    }
}

// MARK: - Touch handling
#if os(iOS)
extension MarbleScene {
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let t = touches.first else { return }
        let p = t.location(in: self)
        blast(at: p)
    }
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let t = touches.first else { return }
        let p = t.location(in: self)
        // Smaller strength while dragging to feel responsive without chaos
        blast(at: p, strength: 2.6, radius: 120)
    }
}
#else
extension MarbleScene {
    override func mouseDown(with event: NSEvent) {
        let p = event.location(in: self)
        blast(at: p)
    }
    override func mouseDragged(with event: NSEvent) {
        let p = event.location(in: self)
        blast(at: p, strength: 2.6, radius: 120)
    }
}
#endif

struct MarblePreviewView: View {
    private let marbleDiameter: CGFloat = 40 // approx 20 radius * 2

    var body: some View {
        VStack(spacing: 24) {
            Circle()
                .fill(Color(MarbleScene.boyBlue))
                .frame(width: marbleDiameter, height: marbleDiameter)
            Circle()
                .fill(Color(MarbleScene.girlPink))
                .frame(width: marbleDiameter, height: marbleDiameter)
            Circle()
                .fill(Color(MarbleScene.lossPurple))
                .frame(width: marbleDiameter, height: marbleDiameter)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.clear)
        .contentShape(Rectangle())
        .padding()
    }
}

#Preview {
    Group {
        MarblePreviewView()
            .background(Color.white)
            .overlay {
                Rectangle()
                    .foregroundStyle(.ultraThinMaterial)
                    .opacity(0.6)
            }
        MarblePreviewView()
            .background(Color.black)
            .preferredColorScheme(.dark)
            .overlay {
                Rectangle()
                    .foregroundStyle(.ultraThinMaterial)
                    .opacity(0.6)
            }
    }
}
