//
//  SampleMarbleView.swift
//  skipapp-stork
//
//  Created by Nick Molargik on 1/22/25.
//

import SwiftUI

struct SampleMarbleView: View {
    let color: Color
    
    var body: some View {
        Circle()
            .fill(
                RadialGradient(
                    gradient: Gradient(colors: [color.opacity(0.6), color]),
                    center: .init(x: 0.35, y: 0.35),
                    startRadius: 5,
                    endRadius: 12
                )
            )
            .shadow(color: Color.black.opacity(0.3), radius: 3, x: 2, y: 2)
            .frame(width: 24, height: 24)
    }
}

#Preview {
    SampleMarbleView(color: Color("storkBlue"))
}
