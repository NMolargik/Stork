//
//  LargeMarblesView.swift
//  
//
//  Created by Nick Molargik on 2/17/25.
//

import SwiftUI

struct LargeMarblesView: View {
    var body: some View {
        HStack(spacing: 50) {
            // Large Blue Marble
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [Color.blue.opacity(0.6), Color.blue]),
                        center: .center,
                        startRadius: 5,
                        endRadius: 75
                    )
                )
                .frame(width: 150, height: 150)
                .shadow(color: Color.black.opacity(0.3), radius: 5, x: 2, y: 2)
            
            // Large Pink Marble
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [Color.pink.opacity(0.6), Color.pink]),
                        center: .center,
                        startRadius: 5,
                        endRadius: 75
                    )
                )
                .frame(width: 150, height: 150)
                .shadow(color: Color.black.opacity(0.3), radius: 5, x: 2, y: 2)
        }
        .padding()
    }
}

struct LargeMarblesView_Previews: PreviewProvider {
    static var previews: some View {
        LargeMarblesView()
    }
}
