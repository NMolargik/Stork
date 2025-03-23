//
//  CustomTextfieldView.swift
//
//
//  Created by Nick Molargik on 11/27/24.
//

import SwiftUI

struct CustomTextfieldView: View {
    @Environment(\.colorScheme) var colorScheme
    
    @EnvironmentObject var appStorageManager: AppStorageManager

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
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .foregroundStyle(iconColor ?? .white)

                Group {
                    if isSecure {
                        SecureField(hintText, text: trimmedText)
                            .foregroundStyle(appStorageManager.useDarkMode ? Color.white : Color.black)
                    } else {
                        TextField(hintText, text: trimmedText)
                            .foregroundStyle(appStorageManager.useDarkMode ? Color.white : Color.black)
                    }
                }
                .frame(height: 50)
                #if !SKIP
                .padding(.horizontal, 5)
                #else
                .padding(.leading, 5)
                #endif
                .textInputAutocapitalization(.never)
            }
            .padding(.leading)
            .background(colorScheme == .dark ? Color.black : Color.white)
            #if !SKIP
            .cornerRadius(20)
            #else
            .cornerRadius(5)
            #endif
            .shadow(color: colorScheme == .dark ? .white : .black, radius: 2)
            .frame(height: 50)

            if let limit = characterLimit {
                Text("\(text.count)/\(limit)")
                    .font(.caption)
                    .foregroundColor(text.count > limit ? .red : .gray)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
        .padding(.horizontal, 5)
    }
}

#Preview {
    VStack(spacing: 20) {
        CustomTextfieldView(
            text: .constant("Email"),
            hintText: "Enter your email...",
            icon: Image("envelope", bundle: .module),
            isSecure: false,
            iconColor: Color("storkBlue"),
            characterLimit: 25
        )

        CustomTextfieldView(
            text: .constant("Password"),
            hintText: "Enter your password...",
            icon: Image("key", bundle: .module),
            isSecure: true,
            characterLimit: 20
        )
    }
    .padding()
    .environmentObject(AppStorageManager())
}
