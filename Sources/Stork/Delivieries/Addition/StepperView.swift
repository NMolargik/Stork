//
//  StepperView.swift
//  skipapp-stork
//
//  Created by Nick Molargik on 1/22/25.
//

import SwiftUI

struct StepperView: View {
    var label: String
    var decrement: () -> Void
    var increment: () -> Void
    var range: ClosedRange<Double>
    
    var body: some View {
        HStack(spacing: 20) {
            CustomStepperButton(systemName: "minus.circle.fill", action: decrement)
            Text(label)
                .frame(minWidth: 70)
                .font(.title3)
                .foregroundStyle(Color.black)
                .fontWeight(.semibold)
            CustomStepperButton(systemName: "plus.circle.fill", action: increment)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Rectangle().cornerRadius(20).foregroundStyle(Color.white.opacity(0.8)))
        .padding(.horizontal)
    }
}

#Preview {
    StepperView(label: "Stepper", decrement: {}, increment: {}, range: 0...1)
}
