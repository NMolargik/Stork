//
//  TiltManager.swift
//  Stork
//
//  Created by Nick Molargik on 10/4/25.
//

import Foundation
import CoreMotion
import UIKit

class TiltManager {
    private let motion = CMMotionManager()
    private let queue = OperationQueue()
    private var lastX = 0.0

    /// Start device motion updates and call the handler with a smoothed horizontal tilt in Gs (-1...1),
    /// mapped to the screen's horizontal axis (accounts for portrait/landscape).
    func start(handler: @escaping (Double) -> Void) {
        guard motion.isDeviceMotionAvailable else { return }
        motion.deviceMotionUpdateInterval = 1.0 / 60.0
        motion.startDeviceMotionUpdates(using: .xArbitraryZVertical, to: queue) { [weak self] data, _ in
            guard let self, let d = data else { return }
            let g = d.gravity
            
            // Map device gravity to screen-horizontal based on interface orientation.
            // portrait:   use +gx for rightward
            // uDown:      invert gx
            // landLeft:   use +gy (so tilting "right" moves marbles right)
            // landRight:  use -gy
            let orientation = TiltManager.currentInterfaceOrientation()
            let rawHorizontal: Double
            switch orientation {
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
            let clamped = max(-1.0, min(1.0, self.lastX))
            handler(clamped)
        }
    }

    func stop() {
        motion.stopDeviceMotionUpdates()
    }
    
    /// Resolve the current interface orientation by inspecting the foreground-active window scenes.
    private static func currentInterfaceOrientation() -> UIInterfaceOrientation {
        if !Thread.isMainThread {
            // Run synchronously on the main thread to avoid UIKit thread violations
            return DispatchQueue.main.sync {
                return currentInterfaceOrientation()
            }
        }
        let scenes = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .filter { $0.activationState == .foregroundActive }
        // Prefer the key window's orientation, otherwise fall back to the first scene's.
        if let key = scenes
            .flatMap({ $0.windows })
            .first(where: { $0.isKeyWindow })?
            .windowScene?
            .interfaceOrientation {
            return key
        }
        return scenes.first?.interfaceOrientation ?? .unknown
    }
}
