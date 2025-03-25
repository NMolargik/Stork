//
//  SplashInfoView.swift
//
//
//  Created by Nick Molargik on 11/4/24.
//

//
//  SplashInfoView.swift
//
//
//  Created by Nick Molargik on 11/4/24.
//

import Foundation
import SwiftUI

struct SplashInfoView: View {
    @Environment(\.dismiss) var dismiss // Allows dismissing the sheet

    var body: some View {
        ZStack {
            VStack {
                Text("About Stork")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Stork is a labor and delivery app designed to assist nurses and doctors in managing delivery statistics over time.")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .padding()
            }
            
            VStack {
                HStack {
                    Spacer()
                    Button(action: {
                        HapticFeedback.trigger(style: .medium)
                        dismiss()
                    }) {
                        Image("xmark.circle.fill", bundle: .module)
                            .foregroundStyle(Color("storkOrange"))
                            .font(.title2)
                    }
                }
                
                Spacer()
            }
        }
        .padding()
    }
}

#Preview {
    SplashInfoView()
}
