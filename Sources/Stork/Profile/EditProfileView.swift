//
//  EditProfileView.swift
//  skipapp-stork
//
//  Created by Nick Molargik on 12/22/24.
//

import SwiftUI
import StorkModel

struct EditProfileView: View {
    // MARK: - Environment Objects
    @EnvironmentObject var profileViewModel: ProfileViewModel
    @EnvironmentObject var musterViewModel: MusterViewModel
    @EnvironmentObject var hospitalViewModel: HospitalViewModel
    @Environment(\.dismiss) var dismiss
    
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
        Form {
            Section(header: Text("Name")) {
                TextField("First Name", text: $firstName)
                
                TextField("Last Name", text: $lastName)
            }
            
            Section(header: Text("Birthday")) {
                DatePicker(
                    "Select Birthday",
                    selection: $birthday,
                    displayedComponents: .date
                )
            }
            
            Section(header: Text("Role")) {
                Picker("Role", selection: $role) {
                    ForEach(ProfileRole.allCases, id: \.self) { role in
                        Text(role.description).tag(role)
                    }
                }
                #if !SKIP
                .pickerStyle(SegmentedPickerStyle())
                #endif
                .onChange(of: role) { _ in
                    triggerHaptic()
                }
            }
            
            if let errorMessage = errorMessage {
                Section {
                    Text(errorMessage)
                        .foregroundColor(.red)
                }
            }
        }
        .navigationTitle("Edit Profile")
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading){
                Button("Cancel") {
                    triggerHaptic()
                    dismiss()
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                if isSaving {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                    ProgressView("Saving...")
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 10).fill(Color.white))
                        .shadow(radius: 10)
                } else {
                    Button("Save") {
                        triggerHaptic()
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
    
    private func triggerHaptic() {
        #if !SKIP
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()
        #endif
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
