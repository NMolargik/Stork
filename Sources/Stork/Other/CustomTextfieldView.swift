//
//  CustomTextfieldView.swift
//
//
//  Created by Nick Molargik on 11/27/24.
//

import SwiftUI

struct CustomTextfieldView: View {
    @Binding var text: String
    var hintText: String
    var icon: Image
    var isSecure: Bool
    var iconColor: Color?
    
    var body: some View {
        HStack {
            icon
                .foregroundStyle(iconColor ?? .primary)
                .frame(width: 20)
            
            Group {
                if (isSecure) {
                    SecureField(hintText, text: $text)
                } else {
                    TextField(hintText, text: $text)
                }
            }
            .colorScheme(.light)
            .textInputAutocapitalization(.never)
            .textFieldStyle(.roundedBorder)
            .padding(.leading, 2)
                
        }
        .padding(.leading)
        .background {
            Color.white
                .cornerRadius(10)
                .shadow(radius: 2)
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        CustomTextfieldView(text: .constant("Email"), hintText: "Enter your email...", icon: Image(systemName: "envelope"), isSecure: false, iconColor: .blue)
        
        CustomTextfieldView(text: .constant("Password"), hintText: "Enter your password...", icon: Image(systemName: "key"), isSecure: true)
    }
    .padding()
}
