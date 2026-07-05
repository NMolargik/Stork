//
//  MarbleScene.swift
//  StorkFeatureDashboard
//
//  The SpriteKit scene behind the marble jar: drops colored marbles for each baby, runs
//  gravity/tilt physics, and "blasts" marbles apart on touch.
//

#if os(iOS)
import SwiftUI
import SpriteKit
import UIKit
import StorkDesignSystem

final class MarbleScene: SKScene {

    func hasAnyMarbles() -> Bool {
        var found = false
        enumerateChildNodes(withName: "marble") { _, stop in
            found = true
            stop.pointee = true
        }
        return found
    }

    var containerCornerRadius: CGFloat = 20 { didSet { rebuildWalls() } }
    var useFrostEffect: Bool = true { didSet { updateFrostVisibility() } }

    private let frostNode = SKShapeNode()
    private var spawnY: CGFloat { size.height - 10 }
    private var marbleRadius: CGFloat {
        if UIDevice.current.userInterfaceIdiom == .pad {
            return max(20, min(size.width, size.height) * 0.025)
        } else {
            return max(18, min(size.width, size.height) * 0.025)
        }
    }

    var onReady: (() -> Void)? { didSet { maybeSignalReady() } }
    private var didSignalReady = false

    static let boyBlue = SKColor.from(.storkBlue)
    static let girlPink = SKColor.from(.storkPink)
    static let lossPurple = SKColor.from(.storkPurple)

    private var pendingBlue = 0
    private var pendingPink = 0
    private var pendingPurple = 0
    private var isReady: Bool { size.width > 10 && size.height > 10 && physicsBody != nil }

    override func didMove(to view: SKView) {
        backgroundColor = .clear
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
        guard useFrostEffect else { return }
        frostNode.fillColor = SKColor.white.withAlphaComponent(isDark ? 0.18 : 0.08)
    }

    private func updateFrostVisibility() {
        frostNode.isHidden = !useFrostEffect
        if !useFrostEffect { frostNode.fillColor = .clear }
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
        guard let onReady else { return }
        didSignalReady = true
        flushPending()
        self.onReady = nil
        DispatchQueue.main.async { onReady() }
    }

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
        let b = pendingBlue, p = pendingPink, r = pendingPurple
        pendingBlue = 0; pendingPink = 0; pendingPurple = 0
        if b > 0 { addMarbles(count: b, color: MarbleScene.boyBlue) }
        if p > 0 { addMarbles(count: p, color: MarbleScene.girlPink) }
        if r > 0 { addMarbles(count: r, color: MarbleScene.lossPurple) }
    }

    func addMarbles(count: Int, color: SKColor) {
        guard count > 0 else { return }
        let wait = SKAction.wait(forDuration: 0.04)
        let spawn = SKAction.run { [weak self] in self?.spawnMarble(color: color) }
        run(SKAction.repeat(SKAction.sequence([spawn, wait]), count: count))
    }

    private func spawnMarble(color: SKColor) {
        let radius = marbleRadius
        let x = CGFloat.random(in: radius...(size.width - radius))
        let node = SKShapeNode(circleOfRadius: radius)
        node.fillColor = color.withAlphaComponent(0.82)
        node.strokeColor = color.withAlphaComponent(0.85)
        node.lineWidth = 1
        node.name = "marble"
        node.position = CGPoint(x: x, y: spawnY)
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

    private func blast(at point: CGPoint, strength: CGFloat = 3.5, radius: CGFloat = 140) {
        enumerateChildNodes(withName: "marble") { node, _ in
            guard let body = node.physicsBody else { return }
            let dx = node.position.x - point.x
            let dy = node.position.y - point.y
            let dist = sqrt(dx * dx + dy * dy)
            guard dist > 1, dist <= radius else { return }
            let nx = dx / dist, ny = dy / dist
            let falloff = max(0, 1.0 - (dist / radius))
            let boost: CGFloat = 1.0 + 0.25 * falloff
            let impulse = strength * falloff * boost
            body.applyImpulse(CGVector(dx: nx * impulse, dy: ny * impulse + 0.2 * impulse))
            body.applyAngularImpulse((Bool.random() ? 1 : -1) * 0.02 * impulse)
        }
    }

    func clearMarbles() {
        enumerateChildNodes(withName: "marble") { node, _ in node.removeFromParent() }
    }

    func resetAndRespawn(blue: Int, pink: Int, purple: Int, completion: @escaping () -> Void) {
        removeAllActions()
        clearMarbles()
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

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let t = touches.first else { return }
        blast(at: t.location(in: self))
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let t = touches.first else { return }
        blast(at: t.location(in: self), strength: 2.6, radius: 120)
    }
}
#endif
