//
//  Marble.swift
//  skipapp-stork
//
//  Created by Nick Molargik on 1/22/25.
//

import Foundation
import SwiftUI

struct Marble: Identifiable {
    let id: UUID
    var position: CGPoint
    var velocity: CGPoint
    let marbleRadius: CGFloat
    let color: Color
    var isActive: Bool = true
    var settledFrames: Int = 0  // Tracks how long a marble has been nearly still
    
    var diameter: CGFloat {
        marbleRadius * 2
    }

    mutating func updateSettledState(velocityThreshold: CGFloat, maxSettledFrames: Int) {
        if abs(velocity.x) < velocityThreshold && abs(velocity.y) < velocityThreshold {
            settledFrames += 1
        } else {
            settledFrames = 0
        }

        if settledFrames >= maxSettledFrames {
            velocity = .zero
        }
    }
}
