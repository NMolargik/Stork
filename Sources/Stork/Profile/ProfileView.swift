//
//  ProfileView.swift
//
//
//  Created by Nick Molargik on 11/4/24.
//

import SwiftUI
import StorkModel

struct ProfileView: View {
    @Environment(\.dismiss) var dismiss
    
    @EnvironmentObject var appStateManager: AppStateManager
    @EnvironmentObject var appStorageManager: AppStorageManager

    @ObservedObject var profileViewModel: ProfileViewModel

    var body: some View {
        NavigationStack {
            ScrollView {
                CustomTextfieldView(text: $profileViewModel.tempProfile.firstName, hintText: "First Name", icon: Image("1.square", bundle: .module), isSecure: false, iconColor: Color.green)
                    .padding(.top)
                
                if let firstNameError = profileViewModel.firstNameError {
                    Text(firstNameError)
                        .font(.caption)
                        .foregroundStyle(.gray)
                        .bold()
                        .padding(.top, -5)
                        .padding(.leading)
                }
                
                CustomTextfieldView(text: $profileViewModel.tempProfile.lastName, hintText: "Last Name", icon: Image("2.square", bundle: .module), isSecure: false, iconColor: Color.green)
                
                if let lastNameError = profileViewModel.lastNameError {
                    Text(lastNameError)
                        .font(.caption)
                        .foregroundStyle(.gray)
                        .padding(.top, -5)
                        .padding(.leading)
                }
                
                Divider()
                
                VStack {
                    Text("Select Your Birthday")
                        .foregroundStyle(appStorageManager.useDarkMode ? Color.white : Color.black)
                    
                    DatePicker("Select Birthday", selection: $profileViewModel.tempProfile.birthday, displayedComponents: [.date])
                        .tint(Color("storkIndigo"))
#if !SKIP
                        .datePickerStyle(.wheel)
#endif
                        .labelsHidden()
                        .environment(\.locale, Locale(identifier: "en_US"))
                        .padding(.top, -15)
                        .padding(.leading)
                    
                }
                .backgroundCard(colorScheme: appStorageManager.useDarkMode ? .dark : .light)
                
                if let birthdayError = profileViewModel.birthdayError {
                    Text(birthdayError)
                        .font(.caption)
                        .foregroundStyle(.gray)
                        .padding(.top, -5)
                        .padding(.leading)
                }

                Divider()
                
                Text("Select Your Role")
                    .foregroundStyle(appStorageManager.useDarkMode ? Color.white : Color.black)
                
                Picker("Role", selection: $profileViewModel.tempProfile.role) {
                    ForEach(ProfileRole.allCases, id: \.self) { role in
                        Text(role.rawValue.capitalized).tag(role)
                    }
                }
                .pickerStyle(.segmented)
                .onChange(of: profileViewModel.tempProfile.firstName) { _ in
                    profileViewModel.validateProfileForm(profileViewModel.tempProfile)
                }
                .onChange(of: profileViewModel.tempProfile.lastName) { _ in
                    profileViewModel.validateProfileForm(profileViewModel.tempProfile)
                }
                .onChange(of: profileViewModel.tempProfile.birthday) { _ in
                    profileViewModel.validateProfileForm(profileViewModel.tempProfile)
                }
                .onChange(of: profileViewModel.tempProfile.role) { _ in
                    profileViewModel.validateProfileForm(profileViewModel.tempProfile)
                }
                .onAppear {
                    startEditingProfile()
                    
                    profileViewModel.validateProfileForm(profileViewModel.tempProfile)
                }
            }
            .padding(.horizontal)
            .padding()
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Text("Editing Profile")
                        .foregroundStyle(appStorageManager.useDarkMode ? Color.white : Color.black)
                        .font(.body)
                        .fontWeight(.bold)
                }
                
                ToolbarItem(placement: .topBarTrailing){
                    Button(action: {
                        HapticFeedback.trigger(style: .medium)
                        stopEditingProfile()
                    }, label: {
                        Text("Save Changes")
                            .font(.body)
                            .fontWeight(.bold)
                            .foregroundStyle(Color("storkOrange"))
                    })
                    .disabled(profileViewModel.isWorking || (profileViewModel.editingProfile && !profileViewModel.isFormValid))
                }
            }
        }
    }
    
    private func startEditingProfile() {
        profileViewModel.editingProfile = true
        profileViewModel.tempProfile = profileViewModel.profile
    }
    
    private func stopEditingProfile() {
        profileViewModel.editingProfile = false
        profileViewModel.isWorking = true
        dismiss()

        Task {
            do {
                try await profileViewModel.updateProfile()
                profileViewModel.editingProfile = false
                profileViewModel.isWorking = false

            } catch {
                profileViewModel.isWorking = false
                withAnimation {
                    appStateManager.errorMessage = error.localizedDescription
                }
            }
        }
    }
}

#Preview {
    ProfileView(profileViewModel: ProfileViewModel(profileRepository: MockProfileRepository(), appStorageManager: AppStorageManager()))
        .environmentObject(AppStateManager.shared)
        .environmentObject(AppStorageManager())
}
