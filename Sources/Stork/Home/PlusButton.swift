//
//  PlusButton.swift
//  skipapp-stork
//
//  Created by Nick Molargik on 1/22/25.
//

import SwiftUI

struct PlusButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: "plus")
                .foregroundStyle(.white)
                .font(.title)
                .fontWeight(.bold)
                .padding(.vertical, 20)
                .frame(maxWidth: .infinity)
                .background {
                    Rectangle()
                        .cornerRadius(20)
                        .foregroundStyle(.indigo)
                        .shadow(radius: 2)
                }
        }
    }
}

#Preview {
    PlusButton(action: {})
}
