//
//  AppStage.swift
//  StorkCore
//
//  The top-level launch state machine driven by RootView: animated branding →
//  onboarding → the main app (iCloud sync runs in the background).
//

import Foundation

nonisolated public enum AppStage: String, Identifiable, Sendable {
    case splash
    case onboarding
    case main

    public var id: String { rawValue }
}
