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
    @AppStorage("appState") var appState: AppState = .register
    @AppStorage("isOnboardingComplete") private var isOnboardingComplete: Bool = false


    @EnvironmentObject var profileViewModel: ProfileViewModel
    @StateObject private var viewModel: LoginViewModel
    
    @State private var isPasswordResetPresented = false
    
    var profileRepository: ProfileRepositoryInterface
    var onAuthenticated: () -> Void
    
    public init(
        profileRepository: ProfileRepositoryInterface = DefaultProfileRepository(remoteDataSource: FirebaseProfileDataSource()),
        onAuthenticated: @escaping () -> Void
    ) {
        self.profileRepository = profileRepository
        self.onAuthenticated = onAuthenticated
        
        _viewModel = StateObject(wrappedValue: LoginViewModel(profileRepository: profileRepository))
    }

    var body: some View {
        ZStack {
            VStack() {
                CustomTextfieldView(text: $viewModel.profile.email, hintText: "Email Address", icon: Image(systemName: "envelope"), isSecure: false, iconColor: Color.blue)
                    .padding(.bottom, 5)
                    .padding(.horizontal)
                
                CustomTextfieldView(text: $viewModel.password, hintText: "Password", icon: Image(systemName: "key"), isSecure: true, iconColor: Color.red)
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
                
                if (viewModel.isWorking) {
                    ProgressView()
                        .tint(.indigo)
                        .frame(height: 40)
                    
                } else {
                    CustomButtonView(text: "Log In", width: 110, height: 40, color: Color.indigo, isEnabled: .constant(true), onTapAction: {
                        Task {
                            do {
                                try await self.signIn()
                            } catch {
                                throw error
                            }
                        }
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
            PasswordResetSheetView(viewModel: viewModel, isPasswordResetPresented: $isPasswordResetPresented, email: $viewModel.profile.email)
                .presentationDetents([PresentationDetent.medium])
        }
    }
    
    private func signIn() async throws {
        do {
            try await viewModel.signInWithEmail()
            onAuthenticated()
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }
}

#Preview {
    LoginView(onAuthenticated: {})
        .environmentObject(ProfileViewModel(profileRepository: MockProfileRepository()))
}
