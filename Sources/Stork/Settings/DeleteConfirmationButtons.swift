//
//  DeleteConfirmationButtons.swift
//  skipapp-stork
//
//  Created by Nick Molargik on 1/22/25.
//

import SwiftUI

struct DeleteConfirmationButtons: View {
    @Binding var step: Int
    @Binding var showing: Bool
    var onDelete: () -> Void

    var body: some View {
        HStack(spacing: 40) {
            CustomButtonView(
                text: "Cancel",
                width: 120,
                height: 50,
                color: .blue,
                isEnabled: true,
                onTapAction: {
                    triggerHaptic()
                    showing = false
                    step = 1
                }
            )
            
            CustomButtonView(
                text: step == 1 ? "Continue" : "Delete",
                width: 120,
                height: 50,
                color: .red,
                isEnabled: true,
                onTapAction: {
                    triggerHaptic()
                    if step == 1 {
                        step = 2
                    } else {
                        onDelete()
                        showing = false
                        step = 1
                    }
                }
            )
        }
    }
}

#Preview {
    DeleteConfirmationButtons(step: .constant(0), showing: .constant(true), onDelete: {})
}
