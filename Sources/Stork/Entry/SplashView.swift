//
//  SplashView.swift
//
//
//  Created by Nick Molargik on 11/4/24.
//

import SwiftUI
import StorkModel

struct SplashView: View {
    @AppStorage("appState") private var appState: AppState = AppState.splash
    @AppStorage("loggedIn") private var loggedIn: Bool = false
    @AppStorage("isOnboardingComplete") private var isOnboardingComplete: Bool = false
    
    @EnvironmentObject var profileViewModel: ProfileViewModel

    @StateObject private var viewModel = SplashViewModel()
    @Binding var showRegistration: Bool
    @State private var isInfoPresented = false
    
    var body: some View {
        ZStack {
            VStack {
                HStack {
                    Spacer()
                    
                    Button(action: {
                        withAnimation {
                            triggerHaptic()
                            isInfoPresented = true
                        }
                    }, label: {
                        Image(systemName: "info.circle.fill")
                            .foregroundStyle(.orange)
                            .font(.title)
                    })
                }
                .padding(.trailing)
                
                Spacer()
                
                Text("Stork")
                    .font(.system(size: 50))
                    .fontWeight(.bold)
                    .opacity(viewModel.isAnimating ? 1.0 : 0.0)
                    .animation(.easeInOut(duration: 1.5), value: viewModel.isAnimating)
                
                if viewModel.showMore {
                    Text("a labor and delivery app")
                        .font(.headline)
                        .fontWeight(.bold)
                        .padding(.bottom)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                
                LoginView(onAuthenticated: {
                    withAnimation {
                        self.loggedIn = true
                        appState = (isOnboardingComplete) ? .main : .onboard
                    }
                })
                .opacity(viewModel.showMore && !loggedIn ? 1.0 : 0.0)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            
                Divider()
                    .scaleEffect(y: 4)
                    .padding(.horizontal)

                Text("Don't have an account yet?")
                    .padding()
                
                CustomButtonView(text: "Sign Up", width: 100, height: 40, color: Color.orange, isEnabled: true, onTapAction: {
                        withAnimation {
                            profileViewModel.resetTempProfile()
                            showRegistration = true
                            appState = AppState.register
                        }
                })
                
                Spacer()
            }
            .toolbar {
                if (!loggedIn) {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            isInfoPresented = !isInfoPresented
                        }) {
                            Image(systemName: "info.circle")
                                .font(.title2)
                                .foregroundColor(.indigo)
                        }
                        .shadow(radius: 5)
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
        .sheet(isPresented: $isInfoPresented) {
            SplashInfoView()
                .transition(.scale.combined(with: .opacity))
                .presentationDetents([.fraction(0.3)])
        }
    }
    
    private func triggerHaptic() {
        #if !SKIP
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()
        #endif
    }
}

#Preview {
    SplashView(showRegistration: .constant(false))
        .environmentObject(ProfileViewModel(profileRepository: MockProfileRepository()))
}
