//
//  SplashView.swift
//
//
//  Created by Nick Molargik on 11/4/24.
//

import SwiftUI
import StorkModel

struct SplashView: View {
    @EnvironmentObject var appStateManager: AppStateManager
    @EnvironmentObject var appStorageManager: AppStorageManager

    @ObservedObject var profileViewModel: ProfileViewModel
    
    @Binding var showRegistration: Bool
    
    @State private var isAnimating = false
    @State private var showMore = false
    @State private var isInfoPresented = false
    
    var onAuthenticated: () -> Void
    
    var body: some View {
        VStack {
            HStack {
                Spacer()
                
                Button(action: {
                    withAnimation {
                        HapticFeedback.trigger(style: .medium)
                        isInfoPresented = true
                    }
                }, label: {
                    Image("info.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                        .foregroundStyle(Color("storkOrange"))
                })
            }
            .padding(.trailing)
            
            Spacer()
            
            Text("Stork")
                .font(.system(size: 50))
                .fontWeight(.bold)
                .opacity(isAnimating ? 1.0 : 0.0)
                .animation(.easeInOut(duration: 1.5), value: isAnimating)
            
            if showMore {
                Text("a labor and delivery app")
                    .font(.headline)
                    .fontWeight(.bold)
                    .padding(.bottom)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            
            LoginView(
                profileViewModel: profileViewModel,
                onAuthenticated: {
                    appStorageManager.dailyDeliveryCount = 0
                    self.onAuthenticated()
                })
            .opacity(showMore ? 1.0 : 0.0)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        
            
            Spacer()
            
            Divider()
                .scaleEffect(y: 4)
                .padding(.horizontal)

            Text("Don't have an account yet?")
                .padding()
            
            CustomButtonView(text: "Sign Up", width: 120, height: 50, color: Color("storkOrange"), isEnabled: true, onTapAction: {
                withAnimation {
                    profileViewModel.resetTempProfile()
                    profileViewModel.passwordText = ""
                    showRegistration = true
                    AppStateManager.shared.currentAppScreen = AppScreen.register
                }
            })
            .padding(.bottom)
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    isInfoPresented = !isInfoPresented
                }) {
                    Image("info.circle")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                        .foregroundColor(Color("storkIndigo"))
                }
                .shadow(radius: 5)
            }
        }
        .padding(.top)
        .frame(maxWidth: .infinity)
        .onAppear {
            startAnimation()
        }
        .sheet(isPresented: $isInfoPresented) {
            SplashInfoView()
                .transition(.scale.combined(with: .opacity))
                .presentationDetents([.fraction(0.3)])
        }
    }

    private func startAnimation() {
        isAnimating = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [self] in
            withAnimation(.easeIn(duration: 0.5)) {
                self.showMore = true
            }
        }
    }
}

#Preview {
    SplashView(
        profileViewModel: ProfileViewModel(profileRepository: MockProfileRepository(), appStorageManager: AppStorageManager()),
        showRegistration: .constant(false), onAuthenticated: {}
    )
    .environmentObject(AppStateManager.shared)
    .environmentObject(AppStorageManager())
}
