//
//  AuthFlowView.swift
//
//
//  Created by Nick Molargik on 11/4/24.
//

import SwiftUI

struct AuthFlowView: View {
    @AppStorage("appState") private var appState: AppState = AppState.splash
    @StateObject private var viewModel: AuthFlowViewModel = AuthFlowViewModel()
    
    var body: some View {
        if (viewModel.showRegistration) {
//            RegisterView(
//                showRegistration: $viewModel.showRegistration,
//                onAuthenticated: {
//                    completeAuthentication()
//                }
//            )
        } else {
            LoginView(
                showRegistration: $viewModel.showRegistration,
                onAuthenticated: {
                    completeAuthentication()
                }
            )
        }
    }
    
    func completeAuthentication() {
        withAnimation {
            appState = AppState.main
        }
    }
}

#Preview {
    AuthFlowView()
}
