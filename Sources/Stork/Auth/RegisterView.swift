//
//  RegisterView.swift
//
//
//  Created by Nick Molargik on 11/4/24.
//

import SwiftUI
//import PhotosUI
import StorkModel

struct RegisterView: View {
    @AppStorage("appState") var appState: AppState = .register
    
    @StateObject private var viewModel: RegisterViewModel = RegisterViewModel()
    @EnvironmentObject var profileViewModel: ProfileViewModel
    @Binding var showRegistration: Bool
    
    //@State private var selectedItem: PhotosPickerItem? = nil
    
    var onAuthenticated: () -> Void

    var body: some View {
        ZStack {
            NavigationStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 10) {
                        CustomTextfieldView(text: $profileViewModel.profile.email, hintText: "Email Address", icon: Image(systemName: "envelope"), isSecure: false, iconColor: Color.blue)
                        
                        if let emailError = viewModel.emailError {
                            Text(emailError)
                                .font(.caption)
                                .foregroundColor(.gray)
                                .padding(.top, -12)
                        }
                        
                        CustomTextfieldView(text: $viewModel.passwordText, hintText: "Password", icon: Image(systemName: "key"), isSecure: true, iconColor: Color.orange)
                        
                        if let passwordError = viewModel.passwordError {
                            Text(passwordError)
                                .font(.caption)
                                .foregroundColor(.gray)
                                .padding(.top, -12)
                        }
                        
                        CustomTextfieldView(text: $viewModel.confirmPassword, hintText: "Confirm Password", icon: Image(systemName: "key"), isSecure: true, iconColor: Color.orange)
                        
                        if let confirmPasswordError = viewModel.confirmPasswordError {
                            Text(confirmPasswordError)
                                .font(.caption)
                                .foregroundColor(.gray)
                                .padding(.top, -12)
                        }
                        
                        CustomTextfieldView(text: $profileViewModel.profile.firstName, hintText: "First Name", icon: Image(systemName: "1.square"), isSecure: false, iconColor: Color.green)
                        
                        if let firstNameError = viewModel.firstNameError {
                            Text(firstNameError)
                                .font(.caption)
                                .foregroundColor(.gray)
                                .bold()
                                .padding(.top, -12)
                        }
                        
                        CustomTextfieldView(text: $profileViewModel.profile.lastName, hintText: "Last Name", icon: Image(systemName: "2.square"), isSecure: false, iconColor: Color.green)
                        
                        if let lastNameError = viewModel.lastNameError {
                            Text(lastNameError)
                                .font(.caption)
                                .foregroundColor(.gray)
                                .padding(.top, -12)
                        }
                        
                        Divider()
                        
                        Text("Select Your Birthday")
                        
                        DatePicker("Select Birthday", selection: $profileViewModel.profile.birthday, displayedComponents: [.date])
                            .tint(.indigo)
                        #if !SKIP
                            .datePickerStyle(WheelDatePickerStyle())
                        #endif
                            .labelsHidden()
                            .environment(\.locale, Locale(identifier: "en_US"))
                            .padding(.top, -15)
                        
                        if let birthdayError = viewModel.birthdayError {
                            Text(birthdayError)
                                .font(.caption)
                                .foregroundColor(.gray)
                                .padding(.top, -12)
                        }
                        
                        Divider()
                        
                        Text("Select Your Role")
                        
                        Picker("Role", selection: $profileViewModel.profile.role) {
                            ForEach(ProfileRole.allCases, id: \.self) { role in
                                Text(role.rawValue.capitalized).tag(role)
                            }
                        }
                        .pickerStyle(.segmented)
                        
                        Divider()
                        
                        VStack {
                            if let image = viewModel.profilePicture {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 100, height: 100)
                                //TODO: fix this for Android
//                                #if !SKIP
//                                    .clipShape(Shape.Circle())
//                                    .overlay(Circle().stroke(Color.orange, lineWidth: 2))
//                                    .shadow(radius: 5.0)
//                                    .padding(Edge.Set.bottom, 10.0)
//                                #endif
                            }
                        
                            HStack {
                                Spacer()
                                
                                //TODO: fix this
//                                PhotosPicker("Select A Profile Picture", selection: $selectedItem, matching: PHPickerFilter.images)
//                                    .onChange(of: selectedItem) { _ in
//                                        Task {
//                                            await viewModel.loadImage(from: selectedItem)
//                                        }
//                                    }
//                                    .tint(Color.blue)
                                
                                Spacer()
                            }
                        }
                        .padding()
                        
                        Divider()
                        
                        HStack {
                            Spacer()
                            
                            if (viewModel.registering) {
                                ProgressView()
                                    .tint(.orange)
                                
                            } else {
                                CustomButtonView(
                                    text: "Sign Up",
                                    width: 120,
                                    height: 40,
                                    color: Color.indigo,
                                    isEnabled: $viewModel.isFormValid,
                                    onTapAction: {
                                        Task {
                                            viewModel.registerWithEmail(profile: profileViewModel.profile, profileRepository: profileViewModel.profileRepository) { profile in
                                                withAnimation {
                                                    profileViewModel.profile = profile
                                                    onAuthenticated()
                                                }
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
        .onChange(of: profileViewModel.profile.email) { _ in
            viewModel.validateForm(profile: profileViewModel.profile)
        }
        .onChange(of: viewModel.passwordText) { _ in
            viewModel.validateForm(profile: profileViewModel.profile)
        }
        .onChange(of: viewModel.confirmPassword) { _ in
            viewModel.validateForm(profile: profileViewModel.profile)
        }
        .onChange(of: profileViewModel.profile.firstName) { _ in
            viewModel.validateForm(profile: profileViewModel.profile)
        }
        .onChange(of: profileViewModel.profile.lastName) { _ in
            viewModel.validateForm(profile: profileViewModel.profile)
        }
        .onChange(of: profileViewModel.profile.birthday) { _ in
            viewModel.validateForm(profile: profileViewModel.profile)
        }
        .onChange(of: profileViewModel.profile.role) { _ in
            viewModel.validateForm(profile: profileViewModel.profile)
        }
        .onAppear {
            viewModel.validateForm(profile: profileViewModel.profile)
        }
    }
}


#Preview {
    RegisterView(showRegistration: .constant(true), onAuthenticated: {})
        .environmentObject(ProfileViewModel(profileRepository: MockProfileRepository()))
}
