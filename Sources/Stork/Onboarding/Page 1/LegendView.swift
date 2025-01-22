//
//  LegendView.swift
//  skipapp-stork
//
//  Created by Nick Molargik on 1/22/25.
//

import SwiftUI

struct LegendView: View {
    var body: some View {
        VStack(alignment: .leading) {
            LegendItemView(color: .blue, label: "Male")
            LegendItemView(color: .pink, label: "Female")
            LegendItemView(color: .purple, label: "Loss")
        }
        .frame(width: 120)
        .padding(.leading, 5)
        .fontWeight(.bold)
    }
}

#Preview {
    LegendView()
}
