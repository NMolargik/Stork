//
//  AppStage.swift
//  Stork
//
//  Created by Nick Molargik on 9/28/25.
//

import Foundation

enum AppStage: String, Identifiable {
    case splash      // Animated branding, "Get Started" button
    case onboarding  // Privacy, Location, Health, Complete
    case syncing     // iCloud data check with timeout
    case main        // Main app experience

    var id: String { self.rawValue }
}
