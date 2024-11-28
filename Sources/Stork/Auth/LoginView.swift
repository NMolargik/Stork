//
//  LoginView.swift
//
//
//  Created by Nick Molargik on 11/4/24.
//

import SwiftUI

struct LoginView: View {
    @StateObject private var viewModel = LoginViewModel()
    //@EnvironmentObject var profileViewModel: ProfileViewModel
    @Binding var showRegistration: Bool
    
    @State private var email: String = ""
    @State private var password: String = ""
    
    var onAuthenticated: () -> Void

    var body: some View {
        ZStack {
            VStack() {
                Group {
                    CustomTextfieldView(text: $email, hintText: "Email Address", icon: Image(systemName: "envelope"), isSecure: false, iconColor: Color.blue)
                        .padding(.bottom, 5)
                    
                    CustomTextfieldView(text: $password, hintText: "Password", icon: Image(systemName: "key"), isSecure: true, iconColor: Color.red)
                        .padding(.bottom)

                    
                }
                .padding(.horizontal)
                
                
                if (viewModel.isWorking) {
                    ProgressView()
                        .tint(.indigo)
                        .frame(height: 40)
                } else {
                    HStack {
                        CustomButtonView(text: "Forgot Your Password?", width: 200, height: 40, color: Color.red, onTapAction: {
      
                            
                        })
                        
                        Spacer()
                        
                        CustomButtonView(text: "Log In", width: 110, height: 40, color: Color.indigo, onTapAction: {
                            //Task {
                            //                            do {
                            //                                try await viewModel.loginWithEmail(profileRepository: profileViewModel.profileRepository)
                            //                                withAnimation {
                            //                                    profileViewModel.profile = viewModel.profile
                            //                                    onAuthenticated()
                            //                                }
                            //                            } catch {
                            //                                if let profileError = error as? ProfileError {
                            //                                    viewModel.handleLoginError(error: profileError)
                            //                                } else {
                            //                                    viewModel.handleLoginError(error: ProfileError.unknown("An unknown error occurred: \(error.localizedDescription)"))
                            //                                }
                            //                            }
                            //                        }
                        })
                    }
                    .padding(.horizontal)

                }
                
                Spacer()
                    .frame(height: 50)
                
                Divider()
                    .scaleEffect(y: 4)
                    .padding(.horizontal)

                Text("Don't have an account yet?")
                    .padding()
                
                CustomButtonView(text: "Sign Up", width: 100, height: 40, color: Color.orange, onTapAction: {
                        withAnimation {
                            showRegistration = true
                        }
                })
            }
            .padding(.horizontal)
            
            if (viewModel.loginError == "") {
                ErrorToastView(error: "Ooops big error", image: Image(systemName: "key.slash"), dismiss: {
                    viewModel.loginError = ""
                })
                    .padding()
            }
        }
            
            
            //        .sheet(isPresented: $viewModel.showPasswordResetSheet) {
            //            PasswordResetSheetView(showPasswordResetSheet: $viewModel.showPasswordResetSheet, email: $viewModel.profile.email, isWorking: $viewModel.isWorking)
            //                .presentationDetents([.medium])
            //                .presentationDragIndicator(.visible)
            //        }
        }
}

#Preview {
    LoginView(showRegistration: .constant(false), onAuthenticated: {})
//        .environmentObject(ProfileViewModel(profileRepository: MockProfileRepository()))
}


//struct PasswordResetSheetView: View {
//    @EnvironmentObject var profileViewModel: ProfileViewModel
//    @Binding var showPasswordResetSheet: Bool
//    @Binding var email: String
//    @Binding var isWorking: Bool
//    @State private var statusMessage: String = ""
//    @State private var showDoneButton: Bool = false
//    
//    var body: some View {
//        VStack {
//            Text("Forgot Your Password?")
//                .font(.title)
//            
//            Text("Provide an email address and we can send a password reset email.")
//                .font(.body)
//                .multilineTextAlignment(.center)
//                .padding()
//            
//            TextField("Email", text: $email)
//                .textFieldStyle(OutlinedTextFieldStyle(icon: Image(systemName: "envelope"), iconColor: Color.blue))
//                .textInputAutocapitalization(.never)
//            
//            if (isWorking) {
//                ProgressView()
//                    .tint(.orange)
//            } else if (showDoneButton) {
//                CustomTextButtonView(text: "Done", backgroundColor: Color.orange, action: {
//                    withAnimation {
//                        showDoneButton = false
//                        showPasswordResetSheet = false
//                    }
//                })
//                .frame(width: 100)
//
//            } else {
//                HStack {
//                    CustomTextButtonView(text: "Submit", backgroundColor: Color.orange, enabled: email.count > 0, action: {
//                        withAnimation {
//                            let resetProfilePasswordUseCase = ResetProfilePasswordUseCase(profileRepository: profileViewModel.profileRepository)
//                            
//                            Task {
//                                do {
//                                    try await resetProfilePasswordUseCase.execute(email: email)
//                                    isWorking = false
//                                    statusMessage = "Email Sent"
//                                    showDoneButton = true
//                                    
//                                    
//                                } catch {
//                                    isWorking = false
//                                    statusMessage = "Failed to send email. Please try again later."
//                                    showDoneButton = true
//                                }
//                            }
//                        }
//                    })
//                    .frame(width: 100)
//                    
//                    CustomTextButtonView(text: "Cancel", backgroundColor: Color.red, action: {
//                        withAnimation {
//                            showPasswordResetSheet = false
//                        }
//                    })
//                    .frame(width: 100)
//                }
//            }
//            
//            if (statusMessage != "") {
//                Text(statusMessage)
//                    .font(.title3)
//                    .multilineTextAlignment(.center)
//            }
//        }
//        .padding()
//    }
//}
