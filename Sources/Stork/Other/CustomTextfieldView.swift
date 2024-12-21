//
//  CustomTextfieldView.swift
//
//
//  Created by Nick Molargik on 11/27/24.
//

import SwiftUI

struct CustomTextfieldView: View {
    @Environment(\.colorScheme) var colorScheme

    @Binding var text: String
    
    var hintText: String
    var icon: Image
    var isSecure: Bool
    var iconColor: Color?
    
    var body: some View {
        HStack {
            icon
                .foregroundStyle(iconColor ?? (colorScheme == .dark ? .white : .black))
                .frame(width: 20)
            
            Group {
                if (isSecure) {
                    SecureField(hintText, text: $text)
                        .frame(height: 50)

                } else {
                    TextField(hintText, text: $text)
                        .frame(height: 50)

                }
            }
            .textInputAutocapitalization(.never)
            .textFieldStyle(.roundedBorder)
            .padding(.leading, 2)
            .padding(.trailing, 5)
                
        }
        .padding(.leading)
        .background {
            if (colorScheme == .dark) {
                Color.gray.opacity(0.5)
                    .cornerRadius(10)
                    .shadow(radius: 2)
            } else {
                Color.white
                    .cornerRadius(10)
                    .shadow(radius: 2)
            }
        }
        .frame(height: 50)
    }
}

#Preview {
    VStack(spacing: 20) {
        CustomTextfieldView(text: .constant("Email"), hintText: "Enter your email...", icon: Image(systemName: "envelope"), isSecure: false, iconColor: .blue)
        
        CustomTextfieldView(text: .constant("Password"), hintText: "Enter your password...", icon: Image(systemName: "key"), isSecure: true)
    }
    .padding()
}
