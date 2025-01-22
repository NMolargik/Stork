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

    private var trimmedText: Binding<String> {
        Binding(
            get: { text },
            set: { newValue in
                if let limit = characterLimit {
                    text = String(newValue.prefix(limit))
                } else {
                    text = newValue
                }
            }
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                icon
                    .foregroundStyle(iconColor ?? .white)
                    .frame(width: 20)

                Group {
                    if isSecure {
                        SecureField(hintText, text: trimmedText)
                    } else {
                        TextField(hintText, text: trimmedText)
                    }
                }
                .frame(height: 50)
                .padding(.horizontal, 5)
                .textInputAutocapitalization(.never)
            }
            .padding(.leading)
            .background(colorScheme == .dark ? Color.black : Color.white)
            .cornerRadius(20)
            .shadow(color: colorScheme == .dark ? .gray : .black, radius: 2)
            .frame(height: 50)

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
            characterLimit: 25
        )

        CustomTextfieldView(
            text: .constant("Password"),
            hintText: "Enter your password...",
            icon: Image(systemName: "key"),
            isSecure: true,
            characterLimit: 20
        )
    }
    .padding()
}
