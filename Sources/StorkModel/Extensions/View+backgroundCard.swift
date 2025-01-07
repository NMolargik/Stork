//
//  View+backgroundCard.swift
//  skipapp-stork
//
//  Created by Nick Molargik on 1/7/25.
//

import Foundation
import SwiftUI

public extension View {
    func backgroundCard(colorScheme: ColorScheme) -> some View {
        self.padding(5)
            .background {
                Rectangle()
                    .foregroundStyle(colorScheme == .dark ? .black : .white)
                    .cornerRadius(20)
                    .shadow(color: colorScheme == .dark ? .white : .black, radius: 2)
            }
            .padding(.horizontal, 5)
    }
}
