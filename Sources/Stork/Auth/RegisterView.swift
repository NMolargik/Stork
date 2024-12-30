//
//  RegisterView.swift
//
//
//  Created by Nick Molargik on 11/4/24.
//

import SwiftUI
import StorkModel
import SkipKit


struct RegisterView: View {
    @AppStorage("errorMessage") var errorMessage: String = ""
    @AppStorage("appState") var appState: AppState = .register
    
    @EnvironmentObject var profileViewModel: ProfileViewModel
    
    @Binding var showRegistration: Bool
    
    var onAuthenticated: () -> Void
    
    public init(
        showRegistration: Binding<Bool>,
        onAuthenticated: @escaping () -> Void
    ) {
        self._showRegistration = showRegistration
        self.onAuthenticated = onAuthenticated
    }

    var body: some View {
        ZStack {
            NavigationStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 10) {
                        CustomTextfieldView(text: $profileViewModel.tempProfile.email, hintText: "Email Address", icon: Image(systemName: "envelope"), isSecure: false, iconColor: Color.blue)
                        
                        if let emailError = profileViewModel.emailError {
                            Text(emailError)
                                .font(.caption)
                                .foregroundColor(.gray)
                                .padding(.top, -5)
                        }
                        
                        CustomTextfieldView(text: $profileViewModel.passwordText, hintText: "Password", icon: Image(systemName: "key"), isSecure: true, iconColor: Color.orange)
                        
                        if let passwordError = profileViewModel.passwordError {
                            Text(passwordError)
                                .font(.caption)
                                .foregroundColor(.gray)
                                .padding(.top, -5)
                        }
                        
                        CustomTextfieldView(text: $profileViewModel.confirmPassword, hintText: "Confirm Password", icon: Image(systemName: "key"), isSecure: true, iconColor: Color.orange)
                        
                        if let confirmPasswordError = profileViewModel.confirmPasswordError {
                            Text(confirmPasswordError)
                                .font(.caption)
                                .foregroundColor(.gray)
                                .padding(.top, -5)
                        }
                        
                        CustomTextfieldView(text: $profileViewModel.tempProfile.firstName, hintText: "First Name", icon: Image(systemName: "1.square"), isSecure: false, iconColor: Color.green)
                        
                        if let firstNameError = profileViewModel.firstNameError {
                            Text(firstNameError)
                                .font(.caption)
                                .foregroundColor(.gray)
                                .bold()
                                .padding(.top, -5)
                        }
                        
                        CustomTextfieldView(text: $profileViewModel.tempProfile.lastName, hintText: "Last Name", icon: Image(systemName: "2.square"), isSecure: false, iconColor: Color.green)
                        
                        if let lastNameError = profileViewModel.lastNameError {
                            Text(lastNameError)
                                .font(.caption)
                                .foregroundColor(.gray)
                                .padding(.top, -5)
                        }
                        
                        Divider()
                        
                        Text("Select Your Birthday")
                        
                        DatePicker("Select Birthday", selection: $profileViewModel.tempProfile.birthday, displayedComponents: [.date])
                            .tint(.indigo)
                        #if !SKIP
                            .datePickerStyle(WheelDatePickerStyle())
                        #endif
                            .labelsHidden()
                            .environment(\.locale, Locale(identifier: "en_US"))
                            .padding(.top, -15)
                        
                        if let birthdayError = profileViewModel.birthdayError {
                            Text(birthdayError)
                                .font(.caption)
                                .foregroundColor(.gray)
                                .padding(.top, -5)
                        }

                        Divider()
                        
                        Text("Select Your Role")
                        
                        Picker("Role", selection: $profileViewModel.tempProfile.role) {
                            ForEach(ProfileRole.allCases, id: \.self) { role in
                                Text(role.rawValue.capitalized).tag(role)
                            }
                        }
                        .pickerStyle(.segmented)
                        
                        Divider()
                        
                        HStack {
                            Spacer()

                            if (profileViewModel.isWorking) {
                                ProgressView()
                                    .tint(.indigo)
                                    .frame(height: 40)
                                    .padding()
                            } else {
                                CustomButtonView(
                                    text: "Sign Up",
                                    width: 120,
                                    height: 40,
                                    color: Color.indigo,
                                    isEnabled: $profileViewModel.isFormValid,
                                    onTapAction: {
                                        Task {
                                            do {
                                                try await profileViewModel.registerWithEmail()
                                                onAuthenticated()
                                            } catch {
                                                self.errorMessage = error.localizedDescription
                                                throw error
                                            }
                                        }
                                    }
                                )
                            }
                            
                            Spacer()
                        }
                    }
                    .padding(20)
                }
                .navigationTitle("Sign Up")
                .toolbar(content: {
                    Button(action: {
                        withAnimation {
                            showRegistration = false
                            appState = AppState.splash
                        }
                    }, label: {
                        Text("Log In Instead")
                            .foregroundStyle(.orange)
                    })
                })
                .frame(maxWidth: .infinity)
            }
        }
        .onChange(of: profileViewModel.tempProfile.email) { _ in
            profileViewModel.validateRegistrationForm()
        }
        .onChange(of: profileViewModel.passwordText) { _ in
            profileViewModel.validateRegistrationForm()
        }
        .onChange(of: profileViewModel.confirmPassword) { _ in
            profileViewModel.validateRegistrationForm()
        }
        .onChange(of: profileViewModel.tempProfile.firstName) { _ in
            profileViewModel.validateRegistrationForm()
        }
        .onChange(of: profileViewModel.tempProfile.lastName) { _ in
            profileViewModel.validateRegistrationForm()
        }
        .onChange(of: profileViewModel.tempProfile.birthday) { _ in
            profileViewModel.validateRegistrationForm()
        }
        .onChange(of: profileViewModel.tempProfile.role) { _ in
            profileViewModel.validateRegistrationForm()
        }
        .onAppear {
            profileViewModel.validateRegistrationForm()
        }
    }
}

#Preview {
    RegisterView(
        showRegistration: .constant(false),
        onAuthenticated: {}
    )
    .environmentObject(ProfileViewModel(profileRepository: MockProfileRepository()))
}
