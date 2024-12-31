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
    
    public init(
        onAuthenticated: @escaping () -> Void
    ) {
        self.onAuthenticated = onAuthenticated
    }

    var body: some View {
        ZStack {
            VStack() {
                CustomTextfieldView(text: $profileViewModel.profile.email, hintText: "Email Address", icon: Image(systemName: "envelope"), isSecure: false, iconColor: Color.blue)
                    .padding(.bottom, 5)
                    .padding(.horizontal)
                
                CustomTextfieldView(text: $profileViewModel.passwordText, hintText: "Password", icon: Image(systemName: "key"), isSecure: true, iconColor: Color.red)
                    .padding(.bottom)
                    .onSubmit {
                        Task {
                            do {
                                try await self.signIn()
                            } catch {
                                throw error
                            }
                        }
                    }
                    .padding(.horizontal)
                
                if (profileViewModel.isWorking) {
                    ProgressView()
                        .tint(.indigo)
                        .frame(height: 40)
                        .padding()
                    
                } else {
                    CustomButtonView(text: "Log In", width: 110, height: 40, color: Color.indigo, isEnabled: true, onTapAction: {
                        Task {
                            do {
                                try await self.signIn()
                            } catch {
                                throw error
                            }
                        }
                    })
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
                    .frame(height: 50)
            }
            .padding(.horizontal)
        }

        .sheet(isPresented: $isPasswordResetPresented) {
            PasswordResetSheetView(isPasswordResetPresented: $isPasswordResetPresented, email: $profileViewModel.profile.email)
                .presentationDetents([PresentationDetent.medium])
        }
    }
    
    private func signIn() async throws {
        do {
            try await profileViewModel.signInWithEmail()
            onAuthenticated()
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }
    
    private func triggerHaptic() {
        #if !SKIP
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()
        #endif
    }
}

#Preview {
    LoginView(onAuthenticated: {})
        .environmentObject(ProfileViewModel(profileRepository: MockProfileRepository()))
}
