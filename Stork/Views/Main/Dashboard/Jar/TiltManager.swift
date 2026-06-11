//
//  TiltManager.swift
//  Stork
//

import Foundation
import CoreMotion
import UIKit

/// Streams smoothed horizontal tilt for the jar's marble physics.
///
/// Motion updates are delivered on the main queue on purpose: this class is
/// MainActor-isolated (Swift 6 default isolation) and its consumer drives
/// SpriteKit physics, which is main-bound anyway. Delivering on a background
/// queue would trap the runtime isolation check the first time a callback
/// fires on a real device.
final class TiltManager {
    private let motion = CMMotionManager()
    private var lastX = 0.0

    /// Start device motion updates and call the handler with a smoothed
    /// horizontal tilt in Gs (-1...1), mapped to the screen's horizontal
    /// axis (accounts for portrait/landscape).
    func start(handler: @escaping (Double) -> Void) {
        guard motion.isDeviceMotionAvailable else { return }
        motion.deviceMotionUpdateInterval = 1.0 / 60.0
        motion.startDeviceMotionUpdates(using: .xArbitraryZVertical, to: .main) { [weak self] data, _ in
            guard let self, let d = data else { return }
            let g = d.gravity

            // Map device gravity to screen-horizontal based on interface orientation.
            // portrait:   use +gx for rightward
            // uDown:      invert gx
            // landLeft:   use +gy (so tilting "right" moves marbles right)
            // landRight:  use -gy
            let rawHorizontal: Double
            switch Self.currentInterfaceOrientation() {
            case .portrait:
                rawHorizontal = g.x
            case .portraitUpsideDown:
                rawHorizontal = -g.x
            case .landscapeLeft:
                rawHorizontal = +g.y
            case .landscapeRight:
                rawHorizontal = -g.y
            default:
                rawHorizontal = g.x
            }

            // Low-pass filter
            let alpha = 0.1
            self.lastX = alpha * rawHorizontal + (1 - alpha) * self.lastX

            // Clamp to a sensible range
            handler(max(-1.0, min(1.0, self.lastX)))
        }
    }

    func stop() {
        motion.stopDeviceMotionUpdates()
    }

    /// Resolve the current interface orientation from the foreground-active
    /// window scenes. Main-actor only, like the rest of this class.
    private static func currentInterfaceOrientation() -> UIInterfaceOrientation {
        let scenes = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .filter { $0.activationState == .foregroundActive }
        // Prefer the key window's orientation, otherwise fall back to the first scene's.
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
