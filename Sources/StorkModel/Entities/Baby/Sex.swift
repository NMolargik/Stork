//
//  Sex.swift
//  
//
//  Created by Nick Molargik on 11/26/24.
//

import Foundation
import SwiftUI

public enum Sex: String, Codable, Hashable {
    case male
    case female
    case loss
    
    public var color: Color {
        switch self {
        case .male:
            return Color.blue
        case .female:
            return Color.pink
        case .loss:
            return Color.purple
        }
    }
}
