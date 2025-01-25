//
//  LoginView.swift
//
//
//  Created by Nick Molargik on 11/4/24.
//

import SwiftUI
import StorkModel

struct LoginView: View {
    @AppStorage("errorMessage") var errorMessage: String = ""
    @AppStorage("isOnboardingComplete") private var isOnboardingComplete: Bool = false

    @EnvironmentObject var profileViewModel: ProfileViewModel
    
    @State private var isPasswordResetPresented = false
    
    var onAuthenticated: () -> Void
    
    public init(onAuthenticated: @escaping () -> Void) {
        self.onAuthenticated = onAuthenticated
    }

    var body: some View {
        ZStack {
            VStack {
                CustomTextfieldView(
                    text: $profileViewModel.profile.email,
                    hintText: "Email Address",
                    icon: Image("envelope"),
                    isSecure: false,
                    iconColor: Color("storkBlue")
                )
                .padding(.bottom, 5)
                .padding(.horizontal)
                
                CustomTextfieldView(
                    text: $profileViewModel.passwordText,
                    hintText: "Password",
                    icon: Image("key"),
                    isSecure: true,
                    iconColor: Color.red
                )
                .padding(.bottom)
                .onSubmit { handleLogin() }
                .padding(.horizontal)
                
                if profileViewModel.isWorking {
                    ProgressView()
                        .tint(Color("storkIndigo"))
                        .frame(height: 50)
                } else {
                    CustomButtonView(
                        text: "Log In",
                        width: 120,
                        height: 50,
                        color: Color("storkIndigo"),
                        isEnabled: true,
                        onTapAction: handleLogin
                    )
                }
                
                Button(action: {
                    withAnimation {
                        triggerHaptic()
                        isPasswordResetPresented = true
                    }
                }, label: {
                    Text("Forgot Your Password?")
                        .foregroundStyle(.red)
                })
                .padding()
                .disabled(profileViewModel.isWorking)
                
                Spacer()
            }
            .padding(.horizontal)
        }

        .sheet(isPresented: $isPasswordResetPresented) {
            PasswordResetSheetView(isPasswordResetPresented: $isPasswordResetPresented, email: $profileViewModel.profile.email)
                .presentationDetents([.medium])
        }
    }
    
    // MARK: - Methods
    private func handleLogin() {
        Task {
            do {
                try await profileViewModel.signInWithEmail()
                onAuthenticated()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}

#Preview {
    LoginView(onAuthenticated: {})
        .environmentObject(ProfileViewModel(profileRepository: MockProfileRepository()))
}
