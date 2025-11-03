//
//  OnboardingUserInfoPage.swift
//  Stork
//
//  Created by Assistant on 10/2/25.
//

import SwiftUI
import Observation

struct OnboardingUserInfoPage: View {
    @Environment(OnboardingView.ViewModel.self) private var onboardingViewModel: OnboardingView.ViewModel

    @State private var showImagePicker = false

    var body: some View {
        NavigationStack {
            @Bindable var viewModel: OnboardingView.ViewModel = onboardingViewModel

            Form {
                Section {
                    VStack(spacing: 12) {
                        Text("We just need a few details to finish up your profile!")
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)

                        Image(systemName: "person.circle")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 120, height: 120)
                            .foregroundStyle(.storkOrange)
                            .padding(.top, 4)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .listRowInsets(EdgeInsets(top: 16, leading: 16, bottom: 8, trailing: 16))
                    .listRowBackground(Color.clear)
                }

                // Fields
                UserEditView(
                    firstName: $viewModel.firstName,
                    lastName: $viewModel.lastName,
                    birthday: $viewModel.birthday,
                    role: $viewModel.role,
                    validationMessage: validationMessage
                )
            }
            .formStyle(.grouped)
        }
        .overlay(alignment: .bottom) {
            if let error = onboardingViewModel.userInfoError, !error.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.yellow)
                    Text(error)
                        .multilineTextAlignment(.leading)
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(.ultraThinMaterial)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(Color.secondary.opacity(0.2))
                )
                .padding()
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .navigationTitle("A Little About You")
        .navigationBarTitleDisplayMode(.large)
        .disabled(onboardingViewModel.isSavingUser)
        .overlay {
            if onboardingViewModel.isSavingUser {
                ZStack {
                    Color.black.opacity(0.05).ignoresSafeArea()
                    ProgressView("Saving your info…")
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(.ultraThinMaterial))
                }
            }
        }
    }

    private var validationMessage: String {
        guard !onboardingViewModel.isAgeValid else { return "" }
        return "You must be at least 15 years old."
    }
}

#Preview {
    NavigationStack {
        OnboardingUserInfoPage()
            .environment(OnboardingView.ViewModel())
    }
}
