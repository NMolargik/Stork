//
//  SplashInfoView.swift
//
//
//  Created by Nick Molargik on 11/4/24.
//

import Foundation
import SwiftUI

struct SplashInfoView: View {
    var body: some View {
        VStack {
            Text("About Stork")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Stork is a labor and delivery app designed to assist healthcare providers in managing weekly delivery statistics.")
                .font(.body)
                .multilineTextAlignment(.center)
                .padding()
        }
        .padding()
        .frame(width: 300)
        .cornerRadius(20)
    }
}

#Preview {
    SplashInfoView()
}
