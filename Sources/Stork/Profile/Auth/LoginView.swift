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
    @State private var keyboardHeight: CGFloat = 0 // Tracks keyboard height
    
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
                    icon: Image(systemName: "envelope"),
                    isSecure: false,
                    iconColor: Color.blue
                )
                .padding(.bottom, 5)
                .padding(.horizontal)
                
                CustomTextfieldView(
                    text: $profileViewModel.passwordText,
                    hintText: "Password",
                    icon: Image(systemName: "key"),
                    isSecure: true,
                    iconColor: Color.red
                )
                .padding(.bottom)
                .onSubmit { handleLogin() }
                .padding(.horizontal)
                
                if profileViewModel.isWorking {
                    ProgressView()
                        .tint(.indigo)
                        .frame(height: 50)
                } else {
                    CustomButtonView(
                        text: "Log In",
                        width: 120,
                        height: 50,
                        color: Color.indigo,
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
                #if !SKIP
                    .frame(height: keyboardHeight > 0 ? 10 : 50) // Adjusts based on keyboard
                #endif
            }
            .padding(.horizontal)
            .padding(.bottom, keyboardHeight / 3) // Moves view up when keyboard appears
            .animation(.easeInOut(duration: 0.3), value: keyboardHeight)
        }
        #if !SKIP
        .onAppear { observeKeyboard() }
        .onDisappear { NotificationCenter.default.removeObserver(self) }
        #endif

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
    
#if !SKIP
    /// Listens for keyboard notifications and updates view padding
    private func observeKeyboard() {
        NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: .main) { notification in
            if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                self.keyboardHeight = keyboardFrame.height - 40 // Adjust spacing to prevent overlapping
            }
        }

        NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: .main) { _ in
            self.keyboardHeight = 0
        }
    }
#endif

}

#Preview {
    LoginView(onAuthenticated: {})
        .environmentObject(ProfileViewModel(profileRepository: MockProfileRepository()))
}
