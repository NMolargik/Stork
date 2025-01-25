//
//  HospitalStatView.swift
//  skipapp-stork
//
//  Created by Nick Molargik on 1/22/25.
//

import SwiftUI

struct HospitalStatView: View {
    @Environment(\.colorScheme) var colorScheme

    let text: String

    var body: some View {
        HStack {
            ZStack {
                Image("figure.child")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .foregroundStyle(Color("storkPurple"))
                    .shadow(radius: 2)
                    .offset(x: 0)
                
                Image("figure.child")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .foregroundStyle(Color("storkPink"))
                    .shadow(radius: 2)
                    .offset(x: 8)
                
                Image("figure.child")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .foregroundStyle(Color("storkBlue"))
                    .shadow(radius: 2)
                    .offset(x: 16)
            }
            .offset(x: -8)
            .frame(width: 30)

            Text(text)
                .fontWeight(.semibold)
        }
        .padding()
        .backgroundCard(colorScheme: colorScheme)
        .padding(.horizontal)
    }
}

#Preview {
    HospitalStatView(text: "1234567890")
}
