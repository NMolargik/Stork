//
//  CustomStepperView.swift
//  skipapp-stork
//
//  Created by Nick Molargik on 1/22/25.
//

import SwiftUI

struct CustomStepperView: View {
    var label: String
    var decrement: () -> Void
    var increment: () -> Void
    var range: ClosedRange<Double>

    @State private var scale: CGFloat = 1.0

    var body: some View {
        HStack(spacing: 20) {
            Spacer()
            
            CustomStepperButtonView(iconName: "minus.circle.fill") {
                animateShrink()
                decrement()
            }
            
            Text(label)
                .frame(minWidth: 70)
                .font(.title3)
                .foregroundStyle(Color.black)
                .fontWeight(.semibold)
            
            CustomStepperButtonView(iconName: "plus.circle.fill") {
                animateBounce()
                increment()
            }

            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            Rectangle()
                .cornerRadius(20)
                .foregroundStyle(Color.white.opacity(0.8))
                .scaleEffect(scale)
                .animation(.spring(response: 0.3, dampingFraction: 0.5, blendDuration: 0), value: scale)
        )
    }

    // MARK: - Animation Methods
    private func animateBounce() {
        scale = 1.1 // Slightly enlarge
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            scale = 1.0 // Return to normal size
        }
    }

    private func animateShrink() {
        scale = 0.95 // Slightly shrink
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            scale = 1.0 // Return to normal size
        }
    }
}

#Preview {
    CustomStepperView(label: "Stepper", decrement: {}, increment: {}, range: 0...1)
}
