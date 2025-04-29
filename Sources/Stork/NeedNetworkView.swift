//
//  SwiftUIView.swift
//  skipapp-stork
//
//  Created by Nick Molargik on 4/26/25.
//

import SwiftUI

/// Shown when the device has no internet connection.
struct NeedNetworkView: View {
    /// Called when the user taps **Try Again**.
    var retry: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Image("wifi.exclamationmark", bundle: .module)
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .foregroundStyle(Color("storkOrange"))

            Text("Internet Required")
                .font(.title3.bold())
                .multilineTextAlignment(.center)
            
            Text("Stork needs an internet connection to verify your subscription and load delivery data.")
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            CustomButtonView(text: "Try Again", width: 300, height: 50, color: Color("storkOrange"), icon: nil, isEnabled: true, onTapAction: {
                retry()
                HapticFeedback.trigger(style: .medium)
            })
            .padding()
        }
    }
}
