//
//  LegendItemView.swift
//  skipapp-stork
//
//  Created by Nick Molargik on 1/22/25.
//

import SwiftUI

struct LegendItemView: View {
    let color: Color
    let label: String
    
    var body: some View {
        HStack {
            SampleMarbleView(color: color)
                .padding(5)
            Text(label)
        }
    }
}

#Preview {
    LegendItemView(color: Color("storkBlue"), label: "Male")
}
