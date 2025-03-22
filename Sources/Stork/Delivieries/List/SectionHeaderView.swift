//
//  SectionHeaderView.swift
//  skipapp-stork
//
//  Created by Nick Molargik on 1/22/25.
//

import SwiftUI

struct SectionHeaderView: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.title)
            .foregroundStyle(.primary)
            .fontWeight(.bold)
            .opacity(0.4)
            .offset(x: -15)
    }
}

#Preview {
    SectionHeaderView(title: "DECEMBER 2025")
}
