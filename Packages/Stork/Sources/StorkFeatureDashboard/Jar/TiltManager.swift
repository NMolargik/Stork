//
//  TiltManager.swift
//  StorkFeatureDashboard
//
//  Streams smoothed horizontal tilt for the jar's marble physics. Motion updates are
//  delivered on the main queue on purpose (this class is MainActor-isolated and drives
//  main-bound SpriteKit physics).
//

#if os(iOS)
import Foundation
import CoreMotion
import UIKit

final class TiltManager {
    /// One CMMotionManager per app and never deallocated: releasing it during scene
    /// teardown on Mac ("Designed for iPad") over-releases a CoreMotion handler and crashes.
    private static let sharedMotion = CMMotionManager()
    private var lastX = 0.0

    private static var isMotionSupported: Bool {
        if ProcessInfo.processInfo.isiOSAppOnMac { return false }
        return sharedMotion.isDeviceMotionAvailable
    }

    func start(handler: @escaping (Double) -> Void) {
        guard Self.isMotionSupported else { return }
        let motion = Self.sharedMotion
        motion.deviceMotionUpdateInterval = 1.0 / 60.0
        motion.startDeviceMotionUpdates(using: .xArbitraryZVertical, to: .main) { [weak self] data, _ in
            guard let self, let d = data else { return }
            let g = d.gravity
            let rawHorizontal: Double
            switch Self.currentInterfaceOrientation() {
            case .portrait: rawHorizontal = g.x
            case .portraitUpsideDown: rawHorizontal = -g.x
            case .landscapeLeft: rawHorizontal = +g.y
            case .landscapeRight: rawHorizontal = -g.y
            default: rawHorizontal = g.x
            }
            let alpha = 0.1
            self.lastX = alpha * rawHorizontal + (1 - alpha) * self.lastX
            handler(max(-1.0, min(1.0, self.lastX)))
        }
    }

    func stop() {
        guard Self.isMotionSupported else { return }
        Self.sharedMotion.stopDeviceMotionUpdates()
    }

    private static func currentInterfaceOrientation() -> UIInterfaceOrientation {
        let scenes = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .filter { $0.activationState == .foregroundActive }
        if let key = scenes
            .flatMap({ $0.windows })
            .first(where: { $0.isKeyWindow })?
            .windowScene?
            .effectiveGeometry.interfaceOrientation {
            return key
        }
        return scenes.first?.effectiveGeometry.interfaceOrientation ?? .unknown
    }
}
#endif
