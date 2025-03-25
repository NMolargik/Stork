//
//  EditProfileView.swift
//  skipapp-stork
//
//  Created by Nick Molargik on 12/22/24.
//

import SwiftUI
import StorkModel

struct EditProfileView: View {
    @Environment(\.dismiss) var dismiss
    
    @EnvironmentObject var appStorageManager: AppStorageManager

    @ObservedObject var profileViewModel: ProfileViewModel
    @ObservedObject var musterViewModel: MusterViewModel
    @ObservedObject var hospitalViewModel: HospitalViewModel
    
    // MARK: - State Variables
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var birthday: Date = Date()
    @State private var role: ProfileRole = .nurse
    @State private var errorMessage: String?
    @State private var isSaving: Bool = false
    
    // Computed property to check if any changes have been made
    private var hasChanges: Bool {
        firstName != profileViewModel.profile.firstName ||
        lastName != profileViewModel.profile.lastName ||
        birthday != profileViewModel.profile.birthday ||
        role != profileViewModel.profile.role
    }
    
    // MARK: - Body
    var body: some View {
        ScrollView {
            Form {
                Section(header: Text("Name")) {
                    TextField("First Name", text: $firstName)
                        .foregroundStyle(appStorageManager.useDarkMode ? Color.white : Color.black)
                    
                    TextField("Last Name", text: $lastName)
                        .foregroundStyle(appStorageManager.useDarkMode ? Color.white : Color.black)
                }
                
                Section(header: Text("Birthday")) {
                    DatePicker(
                        "Select Birthday",
                        selection: $birthday,
                        displayedComponents: .date
                    )
                    .foregroundStyle(appStorageManager.useDarkMode ? Color.white : Color.black)
                }
                
                
                Section(header: Text("Role")) {
                    Picker("Role", selection: $role) {
                        ForEach(ProfileRole.allCases, id: \.self) { role in
                            Text(role.description).tag(role)
                        }
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: role) { _ in
                        HapticFeedback.trigger(style: .medium)
                    }
                }
                
                if let errorMessage = errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                    }
                }
            }
            .padding(.bottom)
        }
        .navigationTitle("Edit Profile")
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading){
                Button("Cancel") {
                    HapticFeedback.trigger(style: .medium)
                    dismiss()
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                if isSaving {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                    ProgressView("Saving...")
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 20).fill(Color.white))
                        .shadow(radius: 2)
                } else {
                    Button("Save") {
                        HapticFeedback.trigger(style: .medium)
                        Task {
                            await saveProfile()
                        }
                    }
                    .disabled(!hasChanges || isSaving)
                }
            }
        }
        .onAppear {
            loadCurrentProfile()
        }
    }
    
    // MARK: - Helper Functions
    
    /// Loads the current profile data into the editable fields.
    private func loadCurrentProfile() {
        firstName = profileViewModel.profile.firstName
        lastName = profileViewModel.profile.lastName
        birthday = profileViewModel.profile.birthday
        role = profileViewModel.profile.role
    }
    
    /// Saves the updated profile data if there are changes.
    private func saveProfile() async {
        guard hasChanges else {
            dismiss()
            return
        }
        
        isSaving = true
        errorMessage = nil
        
        // Create a new Profile object with updated data
        var updatedProfile = profileViewModel.profile
        updatedProfile.firstName = firstName
        updatedProfile.lastName = lastName
        updatedProfile.birthday = birthday
        updatedProfile.role = role
        
        print("Profile changes found. Updating.")
        
        do {
            // Call the updateProfile method in ProfileViewModel
            profileViewModel.tempProfile = updatedProfile
            try await profileViewModel.updateProfile()
            dismiss()
        } catch {
            // Handle errors by displaying an error message
            if let profileError = error as? ProfileError {
                errorMessage = profileError.localizedDescription
            } else {
                errorMessage = "An unexpected error occurred: \(error.localizedDescription)"
            }
        }
        
        isSaving = false
    }
}

#Preview {
    EditProfileView(profileViewModel: ProfileViewModel(profileRepository: MockProfileRepository(), appStorageManager: AppStorageManager()), musterViewModel: MusterViewModel(musterRepository: MockMusterRepository()), hospitalViewModel: HospitalViewModel(hospitalRepository: MockHospitalRepository(), locationProvider: MockLocationProvider()))
        .environmentObject(AppStorageManager())
}
