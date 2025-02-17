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
            LegendItemView(color: Color("storkBlue"), label: "Male")
            LegendItemView(color: Color("storkPink"), label: "Female")
            LegendItemView(color: Color("storkPurple"), label: "Loss")
        }
        .frame(width: 120)
        .padding(.leading, 5)
        .fontWeight(.bold)
    }
}

#Preview {
    LegendView()
}
