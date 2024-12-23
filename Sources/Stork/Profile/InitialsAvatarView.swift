//
//  SwiftUIView.swift
//  skipapp-stork
//
//  Created by Nick Molargik on 12/22/24.
//

import SwiftUI

struct InitialsAvatarView: View {
    // MARK: - Properties
    
    /// The user's first name.
    let firstName: String
    
    /// The user's last name.
    let lastName: String
    
    /// Diameter of the avatar circle.
    var size: CGFloat = 40
    
    /// Font of the initials.
    var font: Font = .headline
    
    // MARK: - Computed Properties
    
    /// Extracts the first initial from the first name.
    private var firstInitial: String {
        guard let first = firstName.first else { return "" }
        return String(first).uppercased()
    }
    
    /// Extracts the first initial from the last name.
    private var lastInitial: String {
        guard let first = lastName.first else { return "" }
        return String(first).uppercased()
    }
    
    /// Combines the first and last initials.
    private var initials: String {
        let combined = firstInitial + lastInitial
        return combined.isEmpty ? "?" : combined
    }
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            Circle()
                .fill(.orange)
                .frame(width: size, height: size)
            
            Text(initials)
                .font(font)
                .foregroundColor(.white)
                .accessibilityLabel(Text("User initials: \(initials)"))
        }
    }
}
