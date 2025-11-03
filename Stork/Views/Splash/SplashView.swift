//
//  SplashView.swift
//  Stork
//
//  Created by Nick Molargik on 10/1/25.
//

import SwiftUI
import SwiftData

struct SplashView: View {
    var checkForExisting: () -> Void
    var attemptLogIn: (String, String) async -> String?
    var moveToOnboarding: () -> Void
    var resetPassword: (String) async throws -> Void
    
    @State private var viewModel = SplashView.ViewModel()
    @State private var showExistingUser = false
    @Environment(\.horizontalSizeClass) private var hSizeClass

    var body: some View {
        VStack {
            Text("Stork")
                .font(.system(size: hSizeClass == .regular ? 90 : 60))
                .bold()
                .opacity(viewModel.titleVisible ? 1 : 0)
                .scaleEffect(viewModel.titleVisible ? 1 : 0.7)
                .animation(.easeOut(duration: 0.6), value: viewModel.titleVisible)
                .padding(.bottom, 5)

            Text("a labor and delivery app")
                .font(hSizeClass == .regular ? .title : .title3)
                .fontWeight(.semibold)
                .opacity(viewModel.subtitleVisible ? 1 : 0)
                .offset(y: viewModel.subtitleVisible ? 0 : 20)
                .animation(.easeOut(duration: 0.6).delay(0.8), value: viewModel.subtitleVisible)

            Image("storkicon")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: hSizeClass == .regular ? 200 : 220)
                .opacity(viewModel.subtitleVisible ? 1 : 0)
                .offset(y: viewModel.subtitleVisible ? 0 : 20)
                .animation(.easeOut(duration: 0.6).delay(0.8), value: viewModel.subtitleVisible)
                .padding()
            
            Spacer()
            
            Button {
                Haptics.lightImpact()
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    checkForExisting()
                    showExistingUser.toggle()
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: showExistingUser ? "chevron.down.circle.fill" : "person.crop.circle.fill")
                    Text(showExistingUser ? "Welcome Back!" : "Existing User")
                        .bold()
                        .frame(width: 140, alignment: .center)
                }
                .padding()
                .frame(maxWidth: 250)
            }
            .adaptiveGlass(tint: .storkPurple)
            .foregroundStyle(.white)
            .padding(.top, 8)
            .opacity(viewModel.subtitleVisible ? 1 : 0)
            .scaleEffect(viewModel.subtitleVisible ? 1 : 0.98)
            .animation(.easeOut(duration: 0.5).delay(1.1), value: viewModel.subtitleVisible)
            .zIndex(1)

            // Expanding container anchored under the Existing User button
            VStack(spacing: 0) {
                VStack(spacing: 14) {
                    HStack(spacing: 12) {
                        Image(systemName: "envelope.fill")
                            .foregroundStyle(.storkBlue)
                            .frame(width: 20)
                        TextField("Email Address", text: $viewModel.email)
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled(true)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(.ultraThinMaterial)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(Color.secondary.opacity(0.15))
                    )

                    HStack(spacing: 12) {
                        Image(systemName: "lock.fill")
                            .foregroundStyle(.storkOrange)
                            .frame(width: 20)
                        SecureField("Password", text: $viewModel.password)
                            .textContentType(.password)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(.ultraThinMaterial)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(Color.secondary.opacity(0.15))
                    )
                }
                .padding(.horizontal)
                .frame(maxWidth: 360)

                Button {
                    Haptics.lightImpact()
                    viewModel.resetEmail = viewModel.email
                    viewModel.resetError = nil
                    viewModel.resetSuccess = false
                    viewModel.showResetPasswordSheet = true
                } label: {
                    Text("Forgot Your Password?")
                        .font(.footnote)
                        .foregroundStyle(.red)
                }
                .buttonStyle(.plain)
                .tint(.storkBlue)
                .padding(.top, 6)

            }
            .padding(.top)
            .opacity(showExistingUser ? 1 : 0)
            .scaleEffect(showExistingUser ? 1 : 0.98, anchor: .top)
            .frame(height: showExistingUser ? nil : 0, alignment: .top)
            .clipped()
            .animation(.spring(response: 0.5, dampingFraction: 0.85), value: showExistingUser)
            
            Button {
                Haptics.lightImpact()
                if showExistingUser {
                    // Attempt login
                    viewModel.loginError = nil
                    viewModel.isLoggingIn = true
                    Task {
                        let errorMessage = await attemptLogIn(viewModel.email, viewModel.password)
                        await MainActor.run {
                            self.viewModel.loginError = errorMessage
                            self.viewModel.isLoggingIn = false
                        }
                    }
                } else {
                    // Go to onboarding for new users
                    moveToOnboarding()
                }
            } label: {
                if showExistingUser {
                    if viewModel.isLoggingIn {
                        ProgressView()
                            .frame(height: 50)
                            .frame(maxWidth: 250)
                    } else {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.right.circle.fill")
                            Text("Log In")
                                .bold()
                                .frame(width: 140, alignment: .center)
                        }
                        .padding()
                        .frame(maxWidth: 250)
                    }
                } else {
                    HStack(spacing: 8) {
                        Image(systemName: "person.crop.circle.badge.plus")
                        Text("New User")
                            .bold()
                            .frame(width: 140, alignment: .center)
                    }
                    .padding()
                    .frame(maxWidth: 250)
                }
            }
            .adaptiveGlass(tint: {
                if showExistingUser {
                    return (viewModel.isLoggingIn ||
                            viewModel.email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                            viewModel.password.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                            !viewModel.email.contains("@")) ? .gray : .storkBlue
                } else {
                    return .storkOrange
                }
            }())
            .foregroundStyle(.white)
            .padding(.top, 8)
            .opacity(viewModel.subtitleVisible ? 1 : 0)
            .scaleEffect(viewModel.subtitleVisible ? 1 : 0.98)
            .animation(.easeOut(duration: 0.5).delay(1.2), value: viewModel.subtitleVisible)
            .disabled(showExistingUser && (
                viewModel.isLoggingIn ||
                viewModel.email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                viewModel.password.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                !viewModel.email.contains("@")
            ))
            .frame(width: 250)
            

            if let loginError = viewModel.loginError {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.yellow)
                    Text(loginError)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.top, 6)
                .padding(.horizontal)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
            
            Spacer()
        }
        .onAppear {
            viewModel.activateAnimation()
        }
        .padding(.top, hSizeClass == .regular ? 40 : 80)
        .frame(maxWidth: hSizeClass == .regular ? 520 : .infinity)
        .padding(.horizontal, 24)
        .sheet(isPresented: $viewModel.showResetPasswordSheet) {
            NavigationStack {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Reset Password")
                        .font(.title2).bold()
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Text("Enter the email address associated with your account.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    HStack(spacing: 12) {
                        Image(systemName: "envelope.fill")
                            .foregroundStyle(.storkBlue)
                            .frame(width: 20)
                        TextField("Email Address", text: $viewModel.resetEmail)
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled(true)
                            .disabled(viewModel.isResettingPassword || viewModel.resetSuccess)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(.ultraThinMaterial)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(Color.secondary.opacity(0.15))
                    )

                    if let resetError = viewModel.resetError {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.yellow)
                            Text(resetError) // TODO: fix ugly error text
                                .foregroundStyle(.red)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(.horizontal)
                    }

                    if viewModel.resetSuccess {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundStyle(.green)
                            Text("Check your email for password reset instructions")
                                .foregroundStyle(.primary)
                        }
                        .transition(.opacity.combined(with: .move(edge: .top)))
                        .padding(.horizontal)
                    }

                    Button {
                        Haptics.lightImpact()
                        attemptPasswordReset()
                    } label: {
                        if viewModel.isResettingPassword {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        } else {
                            Text("Submit")
                                .bold()
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .foregroundStyle(.white)
                    .padding()
                    .adaptiveGlass(tint: viewModel.isResettingPassword || viewModel.resetSuccess || viewModel.resetEmail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !viewModel.resetEmail.contains("@") ? .gray : .storkPurple)
                    .font(.title3)
                    .bold()
                    .disabled(viewModel.isResettingPassword || viewModel.resetSuccess || viewModel.resetEmail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !viewModel.resetEmail.contains("@"))
                    .padding(.top, 4)

                    Spacer(minLength: 0)
                }
                .padding()
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            viewModel.showResetPasswordSheet = false
                        } label: {
                            Image(systemName: "xmark")
                                .font(.body.weight(.semibold))
                        }
                        .accessibilityLabel("Close")
                        .tint(.red)
                        .disabled(viewModel.isResettingPassword)
                    }
                }
            }
            .presentationDetents([.medium])
            .interactiveDismissDisabled(viewModel.isResettingPassword)
        }
    }

    private func attemptPasswordReset() {
        viewModel.isResettingPassword = true
        viewModel.resetError = nil
        Task {
            do {
                try await resetPassword(viewModel.resetEmail.trimmingCharacters(in: .whitespacesAndNewlines))
                await MainActor.run {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        viewModel.resetSuccess = true
                    }
                }
                try? await Task.sleep(nanoseconds: 4_000_000_000)
                await MainActor.run {
                    viewModel.showResetPasswordSheet = false
                    viewModel.resetSuccess = false
                    viewModel.isResettingPassword = false
                    viewModel.resetEmail = ""
                }
            } catch {
                await MainActor.run {
                    if let authError = error as? AuthError {
                        viewModel.resetError = authError.message
                    } else {
                        viewModel.resetError = error.localizedDescription
                    }
                    viewModel.isResettingPassword = false
                }
            }
        }
    }
}

#Preview {
    SplashView(
        checkForExisting: {},
        attemptLogIn: { _,_ in nil },
        moveToOnboarding: {},
        resetPassword: { _ in }
    )
}
