//
//  SplashView.swift
//
//
//  Created by Nick Molargik on 11/4/24.
//

import SwiftUI

struct SplashView: View {
    @AppStorage("appState") private var appState: AppState = AppState.splash
    @AppStorage("isUserLoggedIn") private var isUserLoggedIn: Bool = false

    @StateObject private var viewModel = SplashViewModel()
    @State private var isInfoPresented = false
    
    
    //TODO: add a view of an orange beak holding a bag

    var body: some View {
        ZStack {
            VStack {
                HStack {
                    Spacer()
                    
                    Button(action: {
                        withAnimation {
                            isInfoPresented = true
                        }
                    }, label: {
                        Image(systemName: "info.circle")
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
                
                Spacer()
                
                
                if viewModel.showMore && !isUserLoggedIn {
                    //                        CustomTextButtonView(text: "Get Started", backgroundColor: Color.indigo, action: {
                    //                            withAnimation {
                    //                                viewState = .auth
                    //
                    //                            }
                    //                        })
                    //                        .frame(width: 200, height: 60)
                    //                        .font(.title)
                }
                
                Spacer()
            }
            .toolbar {
                if (!isUserLoggedIn) {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            isInfoPresented = !isInfoPresented
                        }) {
                            Image(systemName: "info.circle")
                                .font(.title2)
                                .foregroundColor(.orange)
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
}

#Preview {
    SplashView()
}
