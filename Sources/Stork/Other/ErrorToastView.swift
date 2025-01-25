//
//  ErrorToastView.swift
//
//
//  Created by Nick Molargik on 11/15/24.
//

import SwiftUI

struct ErrorToastView: View {
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("errorMessage") private var errorMessage: String = ""

    @State private var isVisible: Bool = false

    var body: some View {
        VStack {
            if isVisible {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill") // ✅ Changed to SF Symbol for consistency
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                        .foregroundStyle(.yellow)

                    Text(errorMessage)
                        .foregroundStyle(.primary)
                }
                .padding()
                .backgroundCard(colorScheme: colorScheme)
                .transition(.move(edge: .leading)) // ✅ Transition now applies directly to the HStack
                .onTapGesture {
                    withAnimation {
                        errorMessage = ""
                        isVisible = false
                    }
                }
                .onAppear {
                    withAnimation(.easeOut(duration: 0.3)) {
                        isVisible = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
                        withAnimation {
                            errorMessage = ""
                            isVisible = false
                        }
                    }
                }
            }

            Spacer()
        }
    }
}

#Preview {
    ErrorToastView()
}
