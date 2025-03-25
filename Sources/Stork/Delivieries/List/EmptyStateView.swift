//
//  EmptyStateView.swift
//  skipapp-stork
//
//  Created by Nick Molargik on 1/22/25.
//

import SwiftUI

struct EmptyStateView: View {
    @EnvironmentObject var appStorageManager: AppStorageManager

    var body: some View {
        VStack {
            Spacer()

            HStack(spacing: 16) {
                ForEach(["storkPurple", "storkPink", "storkBlue"], id: \.self) { color in
                    Image("figure.child", bundle: .module)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 50, height: 50)
                        .foregroundStyle(Color(color))
                        .shadow(radius: 2)
                }
            }
            .font(.largeTitle)
            .offset(x: -5)
            .padding(.bottom)

            Text("No deliveries recorded yet. Use the button above to get started!")
                .padding()
                .multilineTextAlignment(.center)
                .font(.body)
                .fontWeight(.semibold)
                .foregroundStyle(appStorageManager.useDarkMode ? Color.white : Color.black)
                .backgroundCard(colorScheme: appStorageManager.useDarkMode ? .dark : .light)

            Spacer(minLength: 200)

            InfoBannerView(
                icon: "exclamationmark.circle",
                text: "You can submit up to 8 deliveries per day",
                color: Color("storkBlue")
            )
        }
        .padding()
    }
}



#Preview {
    EmptyStateView()
        .environmentObject(AppStorageManager())
}
