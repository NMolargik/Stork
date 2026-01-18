//
//  OnboardingUserInfoPage.swift
//  Stork
//
//  Created by Nick Molargik on 10/2/25.
//

import SwiftUI

struct OnboardingUserInfoPage: View {
    @Environment(OnboardingView.ViewModel.self) private var viewModel
    @AppStorage(AppStorageKeys.useDayMonthYearDates) private var useDayMonthYearDates = false

    var body: some View {
        @Bindable var vm = viewModel

        ScrollView {
            VStack(spacing: 32) {
                // Header
                VStack(spacing: 16) {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 64))
                        .foregroundStyle(.storkOrange)
                        .accessibilityHidden(true)

                    Text("About You")
                        .font(.title.bold())

                    Text("Tell us a bit about yourself to personalize your experience.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(.top, 24)

                // Form Fields
                VStack(spacing: 0) {
                    // First Name
                    FormField(icon: "person.fill", iconColor: .storkPurple) {
                        TextField("First Name", text: $vm.firstName)
                            .textContentType(.givenName)
                            .textInputAutocapitalization(.words)
                    }

                    Divider().padding(.leading, 56)

                    // Last Name
                    FormField(icon: "person.fill", iconColor: .storkPurple) {
                        TextField("Last Name", text: $vm.lastName)
                            .textContentType(.familyName)
                            .textInputAutocapitalization(.words)
                    }

                    Divider().padding(.leading, 56)

                    // Birthday
                    FormField(icon: "calendar", iconColor: .red) {
                        HStack {
                            Text("Birthday")
                                .foregroundStyle(.primary)
                            Spacer()
                            DatePicker("", selection: $vm.birthday, displayedComponents: .date)
                                .labelsHidden()
                                .environment(\.locale, useDayMonthYearDates ? Locale(identifier: "en_GB") : Locale.current)
                        }
                    }

                    Divider().padding(.leading, 56)

                    // Role
                    FormField(icon: "stethoscope", iconColor: .storkBlue) {
                        HStack {
                            Text("Role")
                                .foregroundStyle(.primary)
                            Spacer()
                            Picker("", selection: $vm.role) {
                                ForEach(UserRole.allCases) { role in
                                    Text(role.description).tag(role)
                                }
                            }
                            .labelsHidden()
                            .pickerStyle(.segmented)
                            .frame(width: 160)
                        }
                    }
                }
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal, 20)

                // Validation Message
                if !viewModel.isAgeValid {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                        Text("You must be at least 15 years old.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal)
                }

                // Error Message
                if let error = viewModel.userInfoError {
                    HStack(spacing: 8) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.red)
                        Text(error)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .padding(.horizontal, 20)
                }

                Spacer(minLength: 120)
            }
        }
        .scrollIndicators(.hidden)
        .disabled(viewModel.isSavingUser)
    }
}

private struct FormField<Content: View>: View {
    let icon: String
    let iconColor: Color
    @ViewBuilder let content: Content

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(iconColor)
                .frame(width: 28)
                .accessibilityHidden(true)

            content
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}

#Preview {
    OnboardingUserInfoPage()
        .environment(OnboardingView.ViewModel())
}
