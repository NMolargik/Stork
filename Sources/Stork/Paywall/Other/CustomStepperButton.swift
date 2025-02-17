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
    
    var body: some View {
        Button(action: action) {
            Image(iconName)
                .resizable()
                .scaledToFit()
                .frame(width: 30, height: 30)
                .foregroundStyle(Color("storkOrange").opacity(0.7))
        }
    }
}

#Preview {
    CustomStepperButton(iconName: "plus", action: {})
}
