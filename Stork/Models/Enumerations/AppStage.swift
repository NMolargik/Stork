//
//  AppStage.swift
//  Stork
//
//  Created by Nick Molargik on 9/28/25.
//

import Foundation

enum AppStage: String, Identifiable {
    case start
    case splash
    case migration
    case onboarding
    case main
    
    var id: String { self.rawValue }
}
