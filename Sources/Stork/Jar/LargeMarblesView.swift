//
//  LargeMarblesView.swift
//
//
//  Created by Nick Molargik on 2/17/25.
//

import SwiftUI

struct LargeMarblesView: View {
    let colors = ["storkBlue", "storkPink", "storkPurple"]
    
    var body: some View {
        VStack(spacing: 50) {
            ForEach(colors, id: \.self) { color in
                createMarble(color: color)
            }
        }
        .padding()
    }
    
    private func createMarble(color: String) -> some View {
        Circle()
            .fill(
                RadialGradient(
                    gradient: Gradient(colors: [Color(color).opacity(0.6), Color(color)]),
                    center: .center,
                    startRadius: 5,
                    endRadius: 75
                )
            )
            .frame(width: 150, height: 150)
            .shadow(color: Color.black.opacity(0.3), radius: 5, x: 2, y: 2)
    }
}

#Preview {
    LargeMarblesView()
}
