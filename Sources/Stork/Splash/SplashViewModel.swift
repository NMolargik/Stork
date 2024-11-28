//
//  SplashViewModel.swift
//
//
//  Created by Nick Molargik on 11/4/24.
//

import SwiftUI
import Combine

class SplashViewModel: ObservableObject {
    @Published var isAnimating = false
    @Published var showMore = false
    
    init() {
        startAnimation()
    }

    private func startAnimation() {
        isAnimating = true
        
        // Delay using DispatchQueue instead of Just
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            withAnimation(.easeIn(duration: 0.5)) {
                self?.showMore = true
            }
        }
    }
}
