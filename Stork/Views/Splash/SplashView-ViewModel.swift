//
//  SplashView-ViewModel.swift
//  Stork
//
//  Created by Nick Molargik on 8/28/25.
//

import SwiftUI

extension SplashView {
    @Observable
    class ViewModel {
        var titleVisible = false
        var subtitleVisible = false
        var buttonVisible = false
        
        var showResetPasswordSheet: Bool = false
        var resetEmail: String = ""
        var resetError: String? = nil
        var isResettingPassword: Bool = false
        var resetSuccess: Bool = false
        var email: String = ""
        var password: String = ""
        var loginError: String? = nil
        var isLoggingIn: Bool = false
        
        func activateAnimation() {
            withAnimation { self.titleVisible = true }
            withAnimation(Animation.easeOut.delay(0.18)) { self.subtitleVisible = true }
            withAnimation(Animation.spring(response: 0.6, dampingFraction: 0.7).delay(0.5)) { self.buttonVisible = true }
        }
    }
}
