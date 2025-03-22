//
//  CustomStepperButton.swift
//  skipapp-stork
//
//  Created by Nick Molargik on 1/22/25.
//

//
//  CustomStepperButton.swift
//  skipapp-stork
//
//  Created by Nick Molargik on 1/22/25.
//

import SwiftUI

struct CustomStepperButton: View {
    var iconName: String
    var action: () -> Void

    @State private var isHolding = false
    @State private var timer: Timer?

    var body: some View {
        Image(systemName: iconName)
            .resizable()
            .scaledToFit()
            .frame(width: 30, height: 30)
            .foregroundStyle(Color("storkOrange").opacity(0.7))
            .gesture(
                DragGesture(minimumDistance: 0) // Detects tap + hold
                    .onChanged { _ in
                        if !isHolding {
                            isHolding = true
                            startRepeatingAction()
                        }
                    }
                    .onEnded { _ in
                        stopRepeatingAction()
                    }
            )
            .onTapGesture {
                action() // Single tap still works normally
            }
    }

    // MARK: - Start Repeating
    private func startRepeatingAction() {
        action() // Immediate first action
        timer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { _ in
            action()
        }
    }

    // MARK: - Stop Repeating
    private func stopRepeatingAction() {
        isHolding = false
        timer?.invalidate()
        timer = nil
    }
}

#Preview {
    CustomStepperButton(iconName: "plus", action: {})
}
