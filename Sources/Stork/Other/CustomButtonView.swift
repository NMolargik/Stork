//
//  CustomButtonView.swift
//
//
//  Created by Nick Molargik on 11/27/24.
//

import SwiftUI

struct CustomButtonView: View {
    var text: String
    var width: CGFloat
    var height: CGFloat
    var color: Color
    var icon: Image?
    var isEnabled: Bool
    var onTapAction: () -> Void

    var body: some View {
        Button(action: {
            triggerHaptic()
            withAnimation {
                onTapAction()
            }
        }) {
            HStack {
                if let icon = icon {
                    icon
                }
                Text(text)
            }
            .foregroundColor(.white)
            .fontWeight(.bold)
            .frame(width: width, height: height)
        }
        .background(isEnabled ? color : Color.gray)
        .cornerRadius(20)
        .shadow(radius: 2)
        .disabled(!isEnabled)
    }
}

#Preview {
    VStack(spacing: 20) {
        CustomButtonView(
            text: "Push Me",
            width: 200,
            height: 50,
            color: Color.indigo,
            icon: Image(systemName: "building"),
            isEnabled: true,
            onTapAction: {
                print("Push Me button pressed")
            }
        )
        
        CustomButtonView(
            text: "No, Push Me!",
            width: 300,
            height: 50,
            color: Color.blue,
            isEnabled: false,
            onTapAction: {
                print("No, Push Me! button pressed")
            }
        )
    }
    .padding()
}
