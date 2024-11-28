//
//  ErrorToastView.swift
//
//
//  Created by Nick Molargik on 11/15/24.
//

import SwiftUI

struct ErrorToastView: View {
    var error: String
    var image: Image
    var dismiss: () -> Void
    
    var body: some View {
        VStack {
            Spacer()
            
            HStack {
                image
                    .foregroundStyle(.indigo)
                
                Text(error)
                    .foregroundStyle(.primary)
                    .colorInvert()
            }
            .padding()
            .background {
                Color.primary
                    .cornerRadius(14.0)
                    .shadow(radius: 5)
            }
            .onTapGesture {
                withAnimation {
                    dismiss()
                }
            }
        }
    }
}

#Preview {
    ErrorToastView(error: "You messed up bu!.", image: Image(systemName: "person.fill.questionmark"), dismiss: {})
}
