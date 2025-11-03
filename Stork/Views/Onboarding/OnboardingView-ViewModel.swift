//
//  OnboardingView-ViewModel.swift
//  Stork
//
//  Created by Nick Molargik on 10/3/25.
//

import SwiftUI

extension OnboardingView {
    @Observable
    class ViewModel {
        var currentStep: OnboardingStep = .userInfo
        var firstName: String = ""
        var lastName: String = ""
        var birthday: Date = Calendar.current.date(byAdding: .year, value: -20, to: Date()) ?? Date()
        var role: UserRole = .nurse
        var profileImage: Image? = nil
        var profileImageData: Data? = nil
        var isSavingUser: Bool = false
        var userInfoError: String? = nil

        // Validation
        var isAgeValid: Bool {
            let years = Calendar.current.dateComponents([.year], from: birthday, to: Date()).year ?? 0
            return years >= 15
        }
        
        var canContinue: Bool {
            switch currentStep {
            case .userInfo:
                let first = firstName.trimmingCharacters(in: .whitespaces)
                let last  = lastName.trimmingCharacters(in: .whitespaces)
                return !first.isEmpty && !last.isEmpty && isAgeValid && !isSavingUser
            case .location, .health, .complete:
                return true
            }
        }

        var showsSkip: Bool {
            switch currentStep {
            case .location, .health:
                return true
            case .userInfo, .complete:
                return false
            }
        }

        // Actions
        func handleContinueTapped(userManager: UserManager) {
            switch currentStep {
            case .userInfo:
                userInfoError = nil
                isSavingUser = true
                Task {
                    do {
                        // User creation
                        try await createUser(userManager: userManager)
                        await MainActor.run {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                self.currentStep = .location
                            }
                            self.isSavingUser = false
                        }
                    } catch {
                        await MainActor.run {
                            if let userError = error as? UserError {
                                self.userInfoError = userError.errorDescription ?? "Failed to save your profile."
                            } else {
                                self.userInfoError = error.localizedDescription
                            }
                            self.isSavingUser = false
                        }
                    }
                }

            case .location:
                currentStep = .health

            case .health:
                currentStep = .complete

            case .complete:
                break
            }
        }

        func handleSkipTapped() {
            switch currentStep {
            case .location:
                currentStep = .health
            case .health:
                currentStep = .complete
            case .userInfo, .complete:
                break
            }
        }

        private func createUser(userManager: UserManager) async throws {
            let newUser = User()
            newUser.id = UUID()
            newUser.firstName = firstName.trimmingCharacters(in: .whitespaces)
            newUser.lastName = lastName.trimmingCharacters(in: .whitespaces)
            newUser.birthday = birthday
            newUser.role = role

            userManager.update { user in
                user.id = newUser.id
                user.firstName = newUser.firstName
                user.lastName = newUser.lastName
                user.birthday = newUser.birthday
                user.role = newUser.role
            }
        }
    }
}

