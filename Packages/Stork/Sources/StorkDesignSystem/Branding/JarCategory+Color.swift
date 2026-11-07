//
//  JarCategory+Color.swift
//  StorkDesignSystem
//
//  Marble colors for the categorized jar. Remembrance keeps the existing soft purple;
//  nurse catch is orange.
//

import SwiftUI
import StorkCore

public extension JarCategory {
    var color: Color {
        switch self {
        case .boy: .storkBlue
        case .girl: .storkPink
        case .nurseCatch: .storkOrange
        case .remembrance: .storkPurple
        }
    }
}
