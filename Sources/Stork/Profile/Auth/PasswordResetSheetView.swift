//
//  PasswordResetSheetView.swift
//
//
//  Created by Nick Molargik on 11/28/24.
//

import SwiftUI
import StorkModel

#if SKIP
import java.util.regex.Pattern
#endif

struct PasswordResetSheetView: View {
    @AppStorage("errorMessage") var errorMessage: String = ""
    
    @EnvironmentObject var profileViewModel: ProfileViewModel

    @Binding var isPasswordResetPresented: Bool
    @Binding var email: String
    
    @State private var validEmail: Bool = false
    
    var body: some View {
        VStack {
            Text("Forgot Your Password?")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Provide an email address and we can send a password reset email.")
                .font(.body)
                .multilineTextAlignment(.center)
                .padding()
            
            CustomTextfieldView(text: $email, hintText: "Enter your email address...", icon: Image("envelope"), isSecure: false, iconColor: Color("storkBlue"))
                .padding(.bottom)
            
            if (profileViewModel.isWorking) {
                ProgressView()
                    .tint(Color("storkIndigo"))
                    .frame(height: 50)
            } else {
                HStack(spacing: 40) {
                    CustomButtonView(text: "Send", width: 120, height: 40, color: Color("storkIndigo"), isEnabled: validEmail, onTapAction: {
                        Task {
                            do {
                                try await profileViewModel.sendPasswordReset()
                                isPasswordResetPresented = false
                            } catch {
                                errorMessage = error.localizedDescription
                                throw error
                            }
                        }
                    })
                    .onChange(of: email) { email in
                        withAnimation {
                            validEmail = profileViewModel.isEmailValid(email)
                        }
                    }
                    
                    CustomButtonView(text: "Cancel", width: 120, height: 40, color: Color.red, isEnabled: true, onTapAction: {
                        withAnimation {
                            isPasswordResetPresented = false
                        }
                    })
                }
            }
        }
        .padding()
        .onChange(of: email) { _ in
            validEmail = profileViewModel.isEmailValid(email)
        }
    }
}

#Preview {
    PasswordResetSheetView(isPasswordResetPresented: .constant(true), email: .constant("email@email.com"))
        .environmentObject(ProfileViewModel(profileRepository: MockProfileRepository()))
}
