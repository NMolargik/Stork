//
//  HospitalStatView.swift
//  skipapp-stork
//
//  Created by Nick Molargik on 1/22/25.
//

import SwiftUI

struct HospitalStatView: View {
    let icon: String
    let text: String
    let color: Color
    var extraIcons: [String: Color] = [:]

    var body: some View {
        HStack {
            ZStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                
                ForEach(Array(extraIcons.keys.enumerated()), id: \.offset) { index, iconName in
                    Image(systemName: iconName)
                        .foregroundStyle(extraIcons[iconName] ?? .black)
                        .shadow(radius: 2)
                        .offset(x: CGFloat((index + 1) * 8))
                }
            }
            .offset(x: -5)
            .frame(width: 30)

            Text(text)
                .foregroundStyle(.black)
                .fontWeight(.semibold)
        }
        .hospitalInfoBackground()
        .padding(Edge.Set.horizontal)
    }
}

#Preview {
    HospitalStatView(icon: "building.fill", text: "1234567890", color: Color.red)
}
