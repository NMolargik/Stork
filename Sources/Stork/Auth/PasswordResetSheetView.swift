//
//  PasswordResetSheetView.swift
//
//
//  Created by Nick Molargik on 11/28/24.
//

import SwiftUI

#if SKIP
import java.util.regex.Pattern
#endif

struct PasswordResetSheetView: View {
    @Binding var isPasswordResetPresented: Bool
    @Binding var email: String
    @Binding var isWorking: Bool
    
    @State private var validEmail: Bool = false
    
    var body: some View {
        VStack {
            Text("Forgot Your Password?")
                .font(.title)
            
            Text("Provide an email address and we can send a password reset email.")
                .font(.body)
                .multilineTextAlignment(.center)
                .padding()
            
            CustomTextfieldView(text: $email, hintText: "Enter your email address...", icon: Image(systemName: "envelope"), isSecure: false, iconColor: .blue)
                .padding(.bottom)
            
            if (isWorking) {
                ProgressView()
                    .tint(.indigo)
            } else {
                
                CustomButtonView(text: "Send", width: 120, height: 40, color: Color.indigo, isEnabled: $validEmail, onTapAction: {
                    // TODO: send the reset email
                    isPasswordResetPresented = false
                })
                .frame(width: 100)
                .padding(.bottom, 30)
                .onChange(of: email) { email in
                    withAnimation {
                        validEmail = isEmailValid(email: email)
                    }
                }
            }
                
            CustomButtonView(text: "Cancel", width: 120, height: 40, color: Color.red, isEnabled: .constant(true), onTapAction: {
                withAnimation {
                    isPasswordResetPresented = false
                }
            })
        }
        .padding()
        .onChange(of: email) { _ in
            self.validEmail = isEmailValid(email: email)
        }
    }
    
    private func isEmailValid(email: String) -> Bool {
        let emailFormat = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        
        #if !SKIP
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailFormat)
        return emailPredicate.evaluate(with: email)
        #else
        let emailPattern = Pattern.compile(emailFormat)
        return emailPattern.matcher(email).matches()
        #endif
    }
}

#Preview {
    PasswordResetSheetView(isPasswordResetPresented: .constant(true), email: .constant("email@email.com"), isWorking: .constant(false))
}
