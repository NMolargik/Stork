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
import StorkCore
import StorkDesignSystem

final class MarbleScene: SKScene {

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

    /// Marbles waiting for the scene to get a real size.
    private var pendingMarbles: [JarMarble] = []
    /// IDs already spawned or queued, so a repeated sync never double-drops.
    private var knownIDs: Set<UUID> = []
    private var nodesByID: [UUID: SKNode] = [:]
    private var links: [Link] = []
    private var highlight: JarCategory?
    private var isReady: Bool { size.width > 10 && size.height > 10 && physicsBody != nil }

    private struct Link {
        let joint: SKPhysicsJointLimit
        let line: SKShapeNode
        let a: SKNode
        let b: SKNode
        let ids: (UUID, UUID)
    }

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
        // Don't `removeAllActions()` here: SpriteKit reports the size more than once while
        // SwiftUI lays the jar out, and cancelling would kill the drop sequence that
        // `maybeSignalReady()` just started, leaving the jar permanently empty.
        updateFrostFrame()
        rebuildWalls()
        maybeSignalReady()
        if isReady { flushPending() }
    }

    /// Twin "string" color: white vanishes on the light jar, so it flips with the appearance.
    private var linkColor: SKColor = SKColor.darkGray.withAlphaComponent(0.8)

    func applyAppearance(isDark: Bool) {
        linkColor = isDark ? SKColor.white.withAlphaComponent(0.85) : SKColor.darkGray.withAlphaComponent(0.8)
        for link in links { link.line.strokeColor = linkColor }
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

    /// Brings the scene in line with `marbles`: new ones drop in, vanished ones are removed.
    func sync(marbles: [JarMarble]) {
        let wanted = Set(marbles.map(\.id))
        for id in knownIDs.subtracting(wanted) { remove(id: id) }
        pendingMarbles.removeAll { !wanted.contains($0.id) }
        let fresh = marbles.filter { !knownIDs.contains($0.id) }
        guard !fresh.isEmpty else { return }
        knownIDs.formUnion(fresh.map(\.id))
        if !isReady { pendingMarbles += fresh; return }
        drop(fresh)
    }

    private func flushPending() {
        let batch = pendingMarbles
        pendingMarbles = []
        drop(batch)
    }

    private func drop(_ marbles: [JarMarble]) {
        // Keep multiple-birth siblings adjacent so they spawn next to each other and link.
        let ordered = marbles.sorted { ($0.linkID?.uuidString ?? $0.id.uuidString) < ($1.linkID?.uuidString ?? $1.id.uuidString) }
        var actions: [SKAction] = []
        for marble in ordered {
            actions.append(.run { [weak self] in self?.spawn(marble) })
            actions.append(.wait(forDuration: 0.04))
        }
        run(.sequence(actions))
    }

    private func remove(id: UUID) {
        knownIDs.remove(id)
        nodesByID[id]?.removeFromParent()
        nodesByID[id] = nil
        for link in links where link.ids.0 == id || link.ids.1 == id {
            physicsWorld.remove(link.joint)
            link.line.removeFromParent()
        }
        links.removeAll { $0.ids.0 == id || $0.ids.1 == id }
    }

    private var lastSpawnedByLink: [UUID: SKNode] = [:]
    private var lastSpawnedIDByLink: [UUID: UUID] = [:]

    private func spawn(_ marble: JarMarble) {
        guard knownIDs.contains(marble.id), nodesByID[marble.id] == nil else { return }
        let radius = marbleRadius
        let color = SKColor.from(marble.category.color)
        let sibling = marble.linkID.flatMap { lastSpawnedByLink[$0] }
        let x: CGFloat
        if let sibling {
            x = min(max(radius, sibling.position.x + radius * 2.4), size.width - radius)
        } else {
            x = CGFloat.random(in: radius...(size.width - radius))
        }
        let node = SKShapeNode(circleOfRadius: radius)
        node.fillColor = color.withAlphaComponent(0.82)
        node.strokeColor = color.withAlphaComponent(0.85)
        node.lineWidth = 1
        node.name = "marble"
        node.position = CGPoint(x: x, y: spawnY)
        node.zPosition = 1
        node.userData = ["category": marble.category.rawValue]
        // C-section marbles carry a small light core.
        if marble.isCSection {
            let core = SKShapeNode(circleOfRadius: radius * 0.34)
            core.fillColor = SKColor.white.withAlphaComponent(0.9)
            core.strokeColor = .clear
            node.addChild(core)
        }

        let body = SKPhysicsBody(circleOfRadius: radius)
        body.mass = 0.02
        body.restitution = 0.35
        body.friction = 0.6
        body.linearDamping = 0.4
        body.angularDamping = 0.4
        node.physicsBody = body
        addChild(node)
        nodesByID[marble.id] = node
        applyHighlight(to: node)

        if let linkID = marble.linkID {
            if let sibling, let siblingID = lastSpawnedIDByLink[linkID] {
                let joint = SKPhysicsJointLimit.joint(withBodyA: sibling.physicsBody!, bodyB: body, anchorA: .zero, anchorB: .zero)
                joint.maxLength = radius * 4.5
                physicsWorld.add(joint)
                let line = SKShapeNode()
                line.strokeColor = linkColor
                line.lineWidth = 1.5
                line.zPosition = 0.5
                addChild(line)
                links.append(Link(joint: joint, line: line, a: sibling, b: node, ids: (siblingID, marble.id)))
            }
            lastSpawnedByLink[linkID] = node
            lastSpawnedIDByLink[linkID] = marble.id
        }
    }

    /// Keeps each twin "string" drawn between its two marbles.
    override func didSimulatePhysics() {
        for link in links {
            let path = CGMutablePath()
            path.move(to: link.a.position)
            path.addLine(to: link.b.position)
            link.line.path = path
            link.line.alpha = min(link.a.alpha, link.b.alpha)
        }
    }

    /// Dims marbles outside `category` (nil shows everything).
    func setHighlight(_ category: JarCategory?) {
        highlight = category
        for node in nodesByID.values { applyHighlight(to: node) }
    }

    private func applyHighlight(to node: SKNode) {
        guard let highlight else { node.alpha = 1; return }
        node.alpha = (node.userData?["category"] as? String) == highlight.rawValue ? 1 : 0.15
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
        for node in nodesByID.values { node.removeFromParent() }
        for link in links { physicsWorld.remove(link.joint); link.line.removeFromParent() }
        nodesByID = [:]; links = []; knownIDs = []; pendingMarbles = []
        lastSpawnedByLink = [:]; lastSpawnedIDByLink = [:]
    }

    func resetAndRespawn(marbles: [JarMarble], completion: @escaping () -> Void) {
        removeAllActions()
        clearMarbles()
        sync(marbles: marbles.shuffled())
        completion()
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
