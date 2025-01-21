//
//  SplashView.swift
//
//
//  Created by Nick Molargik on 11/4/24.
//

import SwiftUI
import StorkModel

struct SplashView: View {
    // MARK: App Storage Variables
    @AppStorage("appState") private var appState: AppState = AppState.splash
    // MARK: Environment Variables
    @EnvironmentObject var profileViewModel: ProfileViewModel
    
    // MARK: Bindings
    @Binding var showRegistration: Bool
    
    // MARK: Local State Variables
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
                .opacity(isAnimating ? 1.0 : 0.0)
                .animation(.easeInOut(duration: 1.5), value: isAnimating)
            
            if showMore {
                Text("a labor and delivery app")
                    .font(.headline)
                    .fontWeight(.bold)
                    .padding(.bottom)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            
            LoginView(onAuthenticated: {
                self.onAuthenticated()
            })
            .opacity(showMore ? 1.0 : 0.0)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        
            Divider()
                .scaleEffect(y: 4)
                .padding(.horizontal)

            Text("Don't have an account yet?")
                .padding()
            
            CustomButtonView(text: "Sign Up", width: 120, height: 50, color: Color.orange, isEnabled: true, onTapAction: {
                withAnimation {
                    profileViewModel.resetTempProfile()
                    showRegistration = true
                    appState = AppState.register
                }
            })
            
            Spacer()
        }
        .toolbar {
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
    
    private func triggerHaptic() {
        #if !SKIP
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()
        #endif
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
    SplashView(showRegistration: .constant(false), onAuthenticated: {})
        .environmentObject(ProfileViewModel(profileRepository: MockProfileRepository()))
}
