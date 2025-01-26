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
    
    var diameter: CGFloat {
        marbleRadius * 2
    }
}
