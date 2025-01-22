//
//  SectionHeader.swift
//  skipapp-stork
//
//  Created by Nick Molargik on 1/22/25.
//

import SwiftUI

struct SectionHeader: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.title)
            .foregroundStyle(.primary)
            .fontWeight(.bold)
            .opacity(0.2)
            .offset(x: -15)
    }
}

#Preview {
    SectionHeader(title: "DECEMBER 2025")
}
