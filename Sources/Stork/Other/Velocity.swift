//
//  Velocity.swift
//  skipapp-stork
//
//  Created by Nick Molargik on 1/11/25.
//

import Foundation

struct Velocity {
    var dx: CGFloat
    var dy: CGFloat
    
    static var zero: Velocity {
        Velocity(dx: 0, dy: 0)
    }
}
