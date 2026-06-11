//
//  AppStage.swift
//  Stork
//

import Foundation

enum AppStage: String, Identifiable {
    case splash      // Animated branding, "Get Started" button
    case onboarding  // Privacy, Location, Health, Complete
    case main        // Main app experience (iCloud sync runs in the background)

    var id: String { self.rawValue }
}
