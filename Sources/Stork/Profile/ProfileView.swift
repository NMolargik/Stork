import SwiftUI
import StorkModel

struct ProfileView: View {
    @AppStorage("errorMessage") var errorMessage: String = ""

    // MARK: - Environment Objects
    @EnvironmentObject var profileViewModel: ProfileViewModel
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        NavigationStack {
            VStack {
                if (profileViewModel.editingProfile) {
                    CustomTextfieldView(text: $profileViewModel.tempProfile.firstName, hintText: "First Name", icon: Image("1.square"), isSecure: false, iconColor: Color.green)
                    
                    if let firstNameError = profileViewModel.firstNameError {
                        Text(firstNameError)
                            .font(.caption)
                            .foregroundColor(.gray)
                            .bold()
                            .padding(.top, -5)
                    }
                    
                    CustomTextfieldView(text: $profileViewModel.tempProfile.lastName, hintText: "Last Name", icon: Image("2.square"), isSecure: false, iconColor: Color.green)
                    
                    if let lastNameError = profileViewModel.lastNameError {
                        Text(lastNameError)
                            .font(.caption)
                            .foregroundColor(.gray)
                            .padding(.top, -5)
                    }
                    
                    Divider()
                    
                    Text("Select Your Birthday")
                    
                    DatePicker("Select Birthday", selection: $profileViewModel.tempProfile.birthday, displayedComponents: [.date])
                        .tint(Color("storkIndigo"))
                    #if !SKIP
                        .datePickerStyle(.wheel)
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
                        profileViewModel.validateProfileForm(profileViewModel.tempProfile)
                    }
                } else {
                    HStack(alignment: .center) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("\(profileViewModel.profile.role.description) \(profileViewModel.profile.firstName) \(profileViewModel.profile.lastName)")
                                .font(.title2)
                                .fontWeight(.bold)
                                .multilineTextAlignment(.leading)
                            
                            HStack {
                                Image("birthday.cake.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 24, height: 24)
                                
                                Text(Profile.dateFormatter.string(from: profileViewModel.profile.birthday))
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.horizontal)
                        
                        Spacer()
                        
                        VStack {
                            InitialsAvatarView(
                                firstName: profileViewModel.profile.firstName,
                                lastName: profileViewModel.profile.lastName,
                                size: 80.0,
                                font: Font.largeTitle.bold()
                            )
                        }
                        .padding(.trailing)
                    }
                }
            }
            .padding()
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if (!profileViewModel.editingProfile) {
                        Button(action: {
                            triggerHaptic()
                            dismiss()
                        }, label: {
                            Text("Close")
                                .font(.body)
                                .fontWeight(.bold)
                                .foregroundStyle(.red)
                        })
                    } else {
                        Text("Editing Profile")
                            .font(.body)
                            .fontWeight(.bold)
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing){
                    Button(action: {
                        triggerHaptic()
                        withAnimation {
                            if profileViewModel.editingProfile {
                                stopEditingProfile()
                            } else {
                                startEditingProfile()
                            }
                        }
                    }, label: {
                        Text(profileViewModel.editingProfile ? "Save Changes" : "Edit Profile")
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

        Task {
            do {
                try await profileViewModel.updateProfile()
                profileViewModel.editingProfile = false
                profileViewModel.isWorking = false

            } catch {
                profileViewModel.isWorking = false
                errorMessage = error.localizedDescription
            }
        }
    }
}

// MARK: - Preview
struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
            .environmentObject(ProfileViewModel(profileRepository: MockProfileRepository()))
    }
}
