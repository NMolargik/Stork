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
    @Environment(\.colorScheme) var colorScheme

    @EnvironmentObject var appStateManager: AppStateManager
    @EnvironmentObject var appStorageManager: AppStorageManager

    @ObservedObject var profileViewModel: ProfileViewModel
    
    @Binding var showRegistration: Bool
        
    var onAuthenticated: () -> Void
    
    public init(
        profileViewModel: ProfileViewModel,
        showRegistration: Binding<Bool>,
        onAuthenticated: @escaping () -> Void
    ) {
        self.profileViewModel = profileViewModel
        self._showRegistration = showRegistration
        self.onAuthenticated = onAuthenticated
    }

    var body: some View {
        ZStack {
            NavigationStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 10) {
                        CustomTextfieldView(text: $profileViewModel.tempProfile.email, hintText: "Email Address", icon: Image("envelope"), isSecure: false, iconColor: Color("storkBlue"))
                        
                        if let emailError = profileViewModel.emailError {
                            Text(emailError)
                                .font(.caption)
                                .foregroundColor(.red)
                                .bold()
                                .padding(.top, -5)
                                .padding(.leading)
                                .transition(.opacity)
                                .animation(.easeInOut(duration: 0.3), value: profileViewModel.emailError)
                        }
                        
                        CustomTextfieldView(text: $profileViewModel.passwordText, hintText: "Password", icon: Image("key"), isSecure: true, iconColor: Color("storkOrange"))
                        
                        if let passwordError = profileViewModel.passwordError {
                            Text(passwordError)
                                .font(.caption)
                                .foregroundColor(.red)
                                .bold()
                                .padding(.top, -5)
                                .padding(.leading)
                                .transition(.opacity)
                                .animation(.easeInOut(duration: 0.3), value: profileViewModel.passwordError)
                        }
                        
                        CustomTextfieldView(text: $profileViewModel.confirmPassword, hintText: "Confirm Password", icon: Image("key"), isSecure: true, iconColor: Color("storkOrange"))
                        
                        if let confirmPasswordError = profileViewModel.confirmPasswordError {
                            Text(confirmPasswordError)
                                .font(.caption)
                                .foregroundColor(.red)
                                .bold()
                                .padding(.top, -5)
                                .padding(.leading)
                                .transition(.opacity)
                                .animation(.easeInOut(duration: 0.3), value: profileViewModel.confirmPasswordError)
                        }
                        
                        CustomTextfieldView(text: $profileViewModel.tempProfile.firstName, hintText: "First Name", icon: Image("1.square"), isSecure: false, iconColor: Color.green)
                        
                        if let firstNameError = profileViewModel.firstNameError {
                            Text(firstNameError)
                                .font(.caption)
                                .foregroundColor(.red)
                                .bold()
                                .padding(.top, -5)
                                .padding(.leading)
                                .transition(.opacity)
                                .animation(.easeInOut(duration: 0.3), value: profileViewModel.firstNameError)
                        }
                        
                        CustomTextfieldView(text: $profileViewModel.tempProfile.lastName, hintText: "Last Name", icon: Image("2.square"), isSecure: false, iconColor: Color.green)
                        
                        if let lastNameError = profileViewModel.lastNameError {
                            Text(lastNameError)
                                .font(.caption)
                                .foregroundColor(.red)
                                .bold()
                                .padding(.top, -5)
                                .padding(.leading)
                                .transition(.opacity)
                                .animation(.easeInOut(duration: 0.3), value: profileViewModel.lastNameError)
                        }
                        
                        Divider()
                        
                        VStack {
                            Text("Select Your Birthday")
                            
                            DatePicker("Select Birthday", selection: $profileViewModel.tempProfile.birthday, displayedComponents: [.date])
                                .tint(Color("storkIndigo"))
        #if !SKIP
                                .datePickerStyle(.wheel)
        #endif
                                .labelsHidden()
                                .environment(\.locale, Locale(identifier: "en_US"))
                                .padding(.top, -15)
                            
                        }
                        .backgroundCard(colorScheme: colorScheme)
                        
                        if let birthdayError = profileViewModel.birthdayError {
                            Text(birthdayError)
                                .font(.caption)
                                .foregroundColor(.red)
                                .bold()
                                .padding(.top, -5)
                                .padding(.leading)
                                .transition(.opacity)
                                .animation(.easeInOut(duration: 0.3), value: profileViewModel.birthdayError)
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
                                    .tint(Color("storkIndigo"))
                                    .frame(height: 50)
                            } else {
                                CustomButtonView(
                                    text: "Sign Up",
                                    width: 120,
                                    height: 40,
                                    color: Color("storkIndigo"),
                                    isEnabled: true,
                                    onTapAction: {
                                        Task {
                                            do {
                                                try await profileViewModel.registerWithEmail()
                                                onAuthenticated()
                                            } catch {
                                                withAnimation {
                                                    appStateManager.errorMessage = error.localizedDescription
                                                }
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
                            HapticFeedback.trigger(style: .medium)
                            showRegistration = false
                            appStateManager.currentAppScreen = AppScreen.splash
                        }
                    }, label: {
                        Text("Log In Instead")
                            .fontWeight(.bold)
                            .foregroundStyle(Color("storkOrange"))
                    })
                })
                .frame(maxWidth: .infinity)
            }
        }
        .onChange(of: profileViewModel.tempProfile.email) { _ in
            withAnimation {
                profileViewModel.validateRegistrationForm()
            }
        }
        .onChange(of: profileViewModel.passwordText) { _ in
            withAnimation {
                profileViewModel.validateRegistrationForm()
            }
        }
        .onChange(of: profileViewModel.confirmPassword) { _ in
            withAnimation {
                profileViewModel.validateRegistrationForm()
            }
        }
        .onChange(of: profileViewModel.tempProfile.firstName) { _ in
            withAnimation {
                profileViewModel.validateRegistrationForm()
            }
        }
        .onChange(of: profileViewModel.tempProfile.lastName) { _ in
            withAnimation {
                profileViewModel.validateRegistrationForm()
            }
        }
        .onChange(of: profileViewModel.tempProfile.birthday) { _ in
            withAnimation {
                profileViewModel.validateRegistrationForm()
            }
        }
        .onChange(of: profileViewModel.tempProfile.role) { _ in
            withAnimation {
                HapticFeedback.trigger(style: .medium)
                profileViewModel.validateRegistrationForm()
            }
        }
        .onAppear {
            withAnimation {
                profileViewModel.validateRegistrationForm()
            }
        }
    }
}

#Preview {
    RegisterView(
        profileViewModel: ProfileViewModel(profileRepository: MockProfileRepository(), appStorageManager: AppStorageManager()),
        showRegistration: .constant(true),
        onAuthenticated: {}
    )
    .environmentObject(AppStateManager.shared)
    .environmentObject(AppStorageManager())
}
