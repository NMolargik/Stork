//
//  TiltManager.swift
//  Stork
//
//  Created by Nick Molargik on 11/3/25.
//

import Foundation
import CoreMotion

final class TiltManager {
    private let motion = CMMotionManager()
    private let queue = OperationQueue()
    // Low-pass filter state
    private var lastX: Double = 0

    /// Start device motion updates and call the handler with a smoothed horizontal tilt in Gs (-1...1)
    func start(handler: @escaping (Double) -> Void) {
        guard motion.isDeviceMotionAvailable else { return }
        motion.deviceMotionUpdateInterval = 1.0 / 60.0
        motion.startDeviceMotionUpdates(using: .xArbitraryZVertical, to: queue) { [weak self] data, _ in
            guard let self, let d = data else { return }
            // gravity.x is left/right in portrait; keep it subtle and smooth
            let rawX = d.gravity.x
            // Low-pass filter
            let alpha = 0.1
            self.lastX = alpha * rawX + (1 - alpha) * self.lastX
            handler(self.lastX)
        }
    }

    func stop() {
        motion.stopDeviceMotionUpdates()
    }
}
