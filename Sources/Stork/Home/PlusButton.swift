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
            ZStack {
                Rectangle()
                    .foregroundStyle(Color("storkIndigo"))
                    .cornerRadius(20)
                    .shadow(radius: 2)

                Image("plus")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 50, height: 35 )
                    .foregroundStyle(.white)
            }
            .frame(maxWidth: .infinity, minHeight: 60)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 60)
        
        .padding(.horizontal, 5)
    }
}

#Preview {
    PlusButton(action: {})
        .padding()
}
