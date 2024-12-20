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
    @StateObject private var viewModel: RegisterViewModel
    
    @Binding var showRegistration: Bool
    @State private var selectedImageURL: URL?
    
    private let profileRepository: ProfileRepositoryInterface
    var onAuthenticated: () -> Void
    
    public init(
        profileRepository: ProfileRepositoryInterface = DefaultProfileRepository(remoteDataSource: FirebaseProfileDataSource()),
        onAuthenticated: @escaping () -> Void
    ) {
        self.profileRepository = profileRepository
        self.onAuthenticated = onAuthenticated
        
        _viewModel = StateObject(wrappedValue: RegisterViewModel(profileRepository: profileRepository))
    }

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
                                    .clipShape(Circle())
                            } else {
                                Image(systemName: "person.circle")
                                    .foregroundStyle(.orange)
                                    .font(.largeTitle)
                            }
                        
                            HStack {
                                Spacer()
                                
                                MediaButton(type: .library, selectedImageURL: $selectedImageURL, onImageSelected: { url in
                                    if let url = url, let imageData = try? Data(contentsOf: url), let image = UIImage(data: imageData) {
                                            viewModel.profilePicture = image
                                        }
                                })

                                Spacer()
                            }
                        }
                        .padding()
                        
                        Divider()
                        
                        HStack {
                            Spacer()
                            
                            if (viewModel.isWorking) {
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
                                            do {
                                                try await viewModel.registerWithEmail() {
                                                    withAnimation {
                                                        onAuthenticated()
                                                    }
                                                }
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
    RegisterView(profileRepository: MockProfileRepository(), onAuthenticated: {})
    .environmentObject(ProfileViewModel(profileRepository: MockProfileRepository()))
}
