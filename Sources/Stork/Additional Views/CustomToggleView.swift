//
//  CustomToggleView.swift
//
//
//  Created by Nick Molargik on 3/17/25.
//

import SwiftUI

/// A custom toggle view that displays a title and a sliding circle indicator.
struct CustomToggleView: View {
    @Binding var isOn: Bool
    
    var title: String
    var onColor: Color = .green
    var offColor: Color = Color.gray.opacity(0.2)
    var textColor: Color = .black

    var body: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.3)) {
                isOn = !isOn
                HapticFeedback.trigger(style: .medium)
            }
        }) {
            HStack {
                Text(title)
                    .foregroundColor(textColor)
                    .fontWeight(.bold)
                Spacer()
                ZStack(alignment: isOn ? .trailing : .leading) {
                    // Background for the toggle "track"
                    RoundedRectangle(cornerRadius: 20)
                        .fill(isOn ? onColor : offColor)
                        .frame(width: 50, height: 30)
                    // The sliding "thumb"
                    Circle()
                        .fill(Color.white)
                        .frame(width: 26, height: 26)
                        .padding(2)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white.opacity(0.8))
            )
        }
    }
}

#Preview {
    CustomToggleView(isOn: .constant(false), title: "Title")
}
