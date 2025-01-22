//
//  ErrorMessageView.swift
//  skipapp-stork
//
//  Created by Nick Molargik on 1/22/25.
//

import SwiftUI

// MARK: - Error Message View
struct ErrorMessageView: View {
    let errorMessage: String
    
    var body: some View {
        Text(errorMessage)
            .foregroundColor(.red)
            .multilineTextAlignment(.center)
            .padding(.bottom)
    }
}

#Preview {
    ErrorMessageView(errorMessage: "This is an error")
}
