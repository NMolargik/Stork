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
    @State var isEnabled: Bool?

    var onTapAction: () -> Void
    
    var body: some View {
        Button(action: {
            withAnimation {
                onTapAction()
            }
        }, label: {
            Text(text)
                .foregroundStyle(.white)
                .fontWeight(.bold)
                .frame(width: width - 5, height: height - 5)
                .background {
                    // Content
                    (isEnabled ?? true ? color : Color.gray)
                        .cornerRadius(10)
                        .shadow(radius: 5)
                }
        })
        .disabled(!(isEnabled ?? true))
    }
}

#Preview {
    VStack(spacing: 20) {
        CustomButtonView(text: "Push Me", width: 200, height: 50, color: Color.indigo, onTapAction: {})
        
        CustomButtonView(text: "No, Push Me!", width: 300, height: 50, color: Color.blue, isEnabled: false, onTapAction: {})
    }
    .padding()
}
