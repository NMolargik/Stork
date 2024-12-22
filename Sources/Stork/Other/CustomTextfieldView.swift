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
    var characterLimit: Int?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) { // Use VStack to allow space for error message
            HStack {
                icon
                    .foregroundStyle(iconColor ?? .white) // Use iconColor if provided, else default to white
                    .frame(width: 20)
                
                Group {
                    if isSecure {
                        SecureField(hintText, text: $text)
                            .frame(height: 50)
                    } else {
                        TextField(hintText, text: $text)
                            .frame(height: 50)
                    }
                }
                .padding(.leading, 2)
                .padding(.trailing, 5)
                .textInputAutocapitalization(.never)

                .onChange(of: text) { newValue in
                    if let limit = characterLimit, newValue.count > limit {
                        text = String(newValue.prefix(limit))
                    }
                }
            }
            .padding(.leading)
            .background {
                if colorScheme == .dark {
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
            
            // Optional: You can also display the remaining characters here
            if let limit = characterLimit {
                Text("\(text.count)/\(limit)")
                    .font(.caption)
                    .foregroundColor(text.count > limit ? .red : .gray)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        CustomTextfieldView(
            text: .constant("Email"),
            hintText: "Enter your email...",
            icon: Image(systemName: "envelope"),
            isSecure: false,
            iconColor: .blue,
            characterLimit: 25 // Set character limit here
        )
        
        CustomTextfieldView(
            text: .constant("Password"),
            hintText: "Enter your password...",
            icon: Image(systemName: "key"),
            isSecure: true,
            characterLimit: 20 // Example for secure field
        )
    }
    .padding()
}
