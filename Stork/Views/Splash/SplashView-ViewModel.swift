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

        func activateAnimation() {
            withAnimation { self.titleVisible = true }
            withAnimation(Animation.easeOut.delay(0.18)) { self.subtitleVisible = true }
            withAnimation(Animation.spring(response: 0.6, dampingFraction: 0.7).delay(0.5)) { self.buttonVisible = true }
        }
    }
}
