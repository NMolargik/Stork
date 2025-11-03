//
//  OnboardingUserInfoPage.swift
//  Stork
//
//  Created by Assistant on 10/2/25.
//

import SwiftUI

struct OnboardingUserInfoPage: View {
    @Environment(UserManager.self) private var userManager: UserManager
    @Environment(OnboardingView.ViewModel.self) private var viewModel: OnboardingView.ViewModel

    @State private var showImagePicker = false
    @State private var localImage: Image?

    var body: some View {
        Form {
            Section(header: Text("Your Info")) {
                TextField("First Name", text: $viewModel.firstName)
                TextField("Last Name", text: $viewModel.lastName)
                DatePicker("Birthday", selection: $viewModel.birthday, displayedComponents: .date)
                Picker("Role", selection: $viewModel.role) {
                    ForEach(UserRole.allCases) { role in
                        Text(role.description).tag(role)
                    }
                }
            }

            Section(header: Text("Profile Picture (Optional)")) {
                HStack {
                    if let localImage {
                        localImage
                            .resizable()
                            .scaledToFill()
                            .frame(width: 48, height: 48)
                            .clipShape(Circle())
                    } else {
                        Circle().fill(Color.gray.opacity(0.2)).frame(width: 48, height: 48)
                    }
                    Button("Choose Image") {
                        showImagePicker = true
                    }
                }
            }

            Section(footer: Text(validationMessage).foregroundStyle(.secondary)) { }
        }
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showImagePicker) {
            // Placeholder: Implement a real image picker later.
            VStack(spacing: 16) {
                Text("Image Picker Placeholder")
                Button("Use Placeholder") {
                    localImage = Image(systemName: "person.circle.fill")
                    showImagePicker = false
                }
                Button("Cancel") { showImagePicker = false }
            }
            .presentationDetents([.medium])
        }
    }

    private var validationMessage: String {
        guard !viewModel.isAgeValid else { return "" }
        return "You must be at least 15 years old."
    }
}

#Preview {
    NavigationStack {
        OnboardingUserInfoPage()
            .environment(UserManager(authenticationManager: MockAuthenticationManager(), userDataSource: MockUserDataSource()))
            .environment(OnboardingView.ViewModel())
    }
}
