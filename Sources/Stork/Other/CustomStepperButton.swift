//
//  CustomStepperButton.swift
//  skipapp-stork
//
//  Created by Nick Molargik on 1/22/25.
//

import SwiftUI

struct CustomStepperButton: View {
    var systemName: String
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.title)
                .foregroundStyle(Color.black)
        }
    }
}

#Preview {
    CustomStepperButton(systemName: "plus", action: {})
}
