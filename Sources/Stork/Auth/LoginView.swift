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
    @EnvironmentObject var profileViewModel: ProfileViewModel

    @StateObject private var viewModel = LoginViewModel()
    @State private var isPasswordResetPresented = false
    
    var onAuthenticated: () -> Void

    var body: some View {
        ZStack {
            VStack() {
                Group {
                    CustomTextfieldView(text: $viewModel.profile.email, hintText: "Email Address", icon: Image(systemName: "envelope"), isSecure: false, iconColor: Color.blue)
                        .padding(.bottom, 5)
                    
                    CustomTextfieldView(text: $viewModel.password, hintText: "Password", icon: Image(systemName: "key"), isSecure: true, iconColor: Color.red)
                        .padding(.bottom)

                    
                }
                .padding(.horizontal)
                
                
                if (viewModel.isWorking) {
                    ProgressView()
                        .tint(.indigo)
                        .frame(height: 40)
                    
                } else {

                    CustomButtonView(text: "Log In", width: 110, height: 40, color: Color.indigo, isEnabled: .constant(true), onTapAction: {
                        Task {
                            do {
                                try await viewModel.loginWithEmail(profileRepository: profileViewModel.profileRepository)
                                withAnimation {
                                    profileViewModel.profile = viewModel.profile
                                    onAuthenticated()
                                }
                            } catch {
                                errorMessage = error.localizedDescription
                            }
                        }
                        
                        onAuthenticated()
                    })
                    
                    Button(action: {
                        withAnimation {
                            isPasswordResetPresented = true
                        }
                    }, label: {
                        Text("Forgot Your Password?")
                            .foregroundStyle(.red)
                    })
                    .padding()
                }
                
                Spacer()
                    .frame(height: 50)
            }
            .padding(.horizontal)
        }

        .sheet(isPresented: $isPasswordResetPresented) {
            PasswordResetSheetView(isPasswordResetPresented: $isPasswordResetPresented, email: $viewModel.profile.email, isWorking: $viewModel.isWorking)
                .presentationDetents([PresentationDetent.medium])
        }
    }
}

#Preview {
    LoginView(onAuthenticated: {})
        .environmentObject(ProfileViewModel(profileRepository: MockProfileRepository()))
}
