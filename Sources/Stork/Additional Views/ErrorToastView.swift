//
//  ErrorToastView.swift
//
//
//  Created by Nick Molargik on 11/15/24.
//

import SwiftUI

struct ErrorToastView: View {
    @Environment(\.colorScheme) var colorScheme
    
    @EnvironmentObject var appStateManager: AppStateManager

    var body: some View {
        VStack {
            HStack {
                Image("exclamationmark.triangle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .foregroundStyle(.yellow)
                
                Text(appStateManager.errorMessage)
            }
            .padding()
            .backgroundCard(colorScheme: colorScheme)
            .onTapGesture {
                withAnimation {
                    appStateManager.errorMessage = ""
                }
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
                    withAnimation {
                        appStateManager.errorMessage = ""
                    }
                }
            }
            
            Spacer()
        }
        .transition(.move(edge: .top))
    }
}

#Preview {
    ErrorToastView()
        .environmentObject(AppStateManager.shared)
}
