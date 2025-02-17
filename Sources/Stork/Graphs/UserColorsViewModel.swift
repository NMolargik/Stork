//
//  UserColorsViewModel.swift
//  skipapp-stork
//
//  Created by Nick Molargik on 1/14/25.
//

import SwiftUI
import StorkModel

class UserColorsViewModel: ObservableObject {
    @Published var userColors: [String: Color] = [:]

    /// Generates or updates colors for all profiles
    func generateUserColors(for profiles: [Profile]) {
        // Remove colors for missing profiles
        userColors = userColors.filter { key, _ in key == "Old Members" || profiles.contains { $0.id == key } }
        
        // Add colors for new profiles
        for profile in profiles {
            if userColors[profile.id] == nil {
                userColors[profile.id] = randomColor()
            }
        }
        
        // Ensure "Other" has a color
        if userColors["Old Members"] == nil {
            userColors["Old Members"] = .gray // Or a distinct color of your choice
        }
    }

    /// Returns a random color
    private func randomColor() -> Color {
        let red = Double.random(in: 0.0...1.0)
        let green = Double.random(in: 0.0...1.0)
        let blue = Double.random(in: 0.0...1.0)
        return Color(red: red, green: green, blue: blue)
    }
}
