//
//  MetricRowView.swift
//  Stork
//
//  Created by Nick Molargik on 10/26/25.
//

import SwiftUI

struct MetricRowView<Value: View>: View {
    let title: String
    let valueView: Value
    
    init(_ title: String, @ViewBuilder value: () -> Value) {
        self.title = title
        self.valueView = value()
    }
    
    init(_ title: String, value: String) where Value == Text {
        self.title = title
        self.valueView = Text(value)
    }
    
    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .foregroundStyle(.secondary)
                .font(.subheadline)
            Spacer()
            valueView
                .font(.subheadline)
        }
    }
}

#Preview {
    MetricRowView("Labeled Row", value: "Sample Value")
}
