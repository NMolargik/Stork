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
            HapticFeedback.trigger(style: .medium)
            withAnimation {
                onTapAction()
            }
        }) {
            HStack(spacing: 5) {
                if let icon = icon {
                    icon
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                        .foregroundStyle(.white)
                }
                
                Text(text)
            }
            .foregroundStyle(.white)
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
            color: Color("storkIndigo"),
            icon: Image("building.fill", bundle: .module),
            isEnabled: true,
            onTapAction: {
                print("Push Me button pressed")
            }
        )
        
        CustomButtonView(
            text: "No, Push Me!",
            width: 300,
            height: 50,
            color: Color("storkBlue"),
            isEnabled: false,
            onTapAction: {
                print("No, Push Me! button pressed")
            }
        )
    }
    .padding()
}
