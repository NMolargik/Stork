//
//  ScalableText.swift
//
//
//  Created by Nick Molargik on 3/16/25.
//

import SwiftUI

struct ScalableText: View {
    let text: String
    let minWidth: CGFloat
    let maxSize: CGFloat = 24

    var body: some View {
        GeometryReader { geometry in
            Text(text)
                .font(.system(size: min(geometry.size.width * 0.4, maxSize)))
                .frame(width: geometry.size.width, height: geometry.size.height)
                .scaledToFit()
        }
        .frame(width: minWidth, height: 25)
    }
}

#Preview {
    ScalableText(text: "Text", minWidth: 10.0)
}
