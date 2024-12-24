//
//  SwiftUIView.swift
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
                ToolbarItem(placement: .topBarLeading){
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        saveProfile()
                    }
                    .disabled(isSaving)
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
    
    /// Saves the updated profile data. Placeholder for actual save functionality.
    private func saveProfile() {
        isSaving = true
        errorMessage = nil
        
        // Update the tempProfile in the ViewModel
        profileViewModel.tempProfile.firstName = firstName
        profileViewModel.tempProfile.lastName = lastName
        profileViewModel.tempProfile.birthday = birthday
        profileViewModel.tempProfile.role = role
        
        // Placeholder for actual save functionality
        // Replace this with your save logic, such as calling an async function
        // For now, we'll simulate a save with a delay
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            // Simulate successful save
            isSaving = false
            dismiss()
            
            // In a real implementation, you would handle errors and update the profileViewModel accordingly
        }
    }
}
